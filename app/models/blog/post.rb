# frozen_string_literal: true
class Blog::Post < Blog::ApplicationRecord
  include ModelConcerns::HasShortUrl
  include ModelConcerns::Trackable
  include ModelConcerns::Shared::Likeable
  include ModelConcerns::Shared::HasAbsolutePath
  include ModelConcerns::ActiveModel::Extensions
  include ModelConcerns::Shared::Blog::HasMentions
  include ModelConcerns::Shared::Viewable
  include ModelConcerns::Shared::HasPromoWeight
  include ModelConcerns::Blog::Post::PgSearchable

  extend FriendlyId

  class << self
    def visible_for_user(user = nil)
      if Rails.application.credentials.global[:enterprise]
        visible_for_user_enterprise(user)
      else
        visible_for_user_marketplace(user)
      end
    end

    def visible_for_user_enterprise(user = nil)
      return none if !user.is_a?(User) || !user.persisted?
      return where(nil) if user.service_admin? || user.platform_owner?

      channels_with_manage_credentials = user.all_channels_with_credentials(%i[manage_blog_post
                                                                               moderate_blog_post]).pluck(:id).uniq
      channels_with_member_credentials = user.all_channels_with_credentials(::AccessManagement::Credential::Codes::VIEW_CONTENT).pluck(:id)
      return none if channels_with_manage_credentials.blank? && channels_with_member_credentials.blank?

      where(%{blog_posts.channel_id IN (:manage_channel_ids) OR blog_posts.status = :published AND blog_posts.channel_id IN (:member_channel_ids)},
            { published: ::Blog::Post::Statuses::PUBLISHED,
              manage_channel_ids: channels_with_manage_credentials,
              member_channel_ids: channels_with_member_credentials })
    end

    def visible_for_user_marketplace(user = nil)
      if user.is_a?(User) && user.persisted? && (user.service_admin? || user.platform_owner?)
        where(nil)
      elsif user.is_a?(User) && user.persisted? && (channels_with_manage_credentials = user.all_channels_with_credentials(%i[manage_blog_post moderate_blog_post]).pluck(:id).uniq).present?
        where(%{blog_posts.status = :published OR blog_posts.channel_id IN (:channel_ids)},
              published: ::Blog::Post::Statuses::PUBLISHED, channel_ids: channels_with_manage_credentials)
      else
        where(status: ::Blog::Post::Statuses::PUBLISHED)
      end
    end
  end

  friendly_id :title, use: :slugged

  acts_as_votable
  acts_as_ordered_taggable_on :tags
  module Statuses
    DRAFT = 'draft'
    PUBLISHED = 'published'
    HIDDEN = 'hidden'
    ARCHIVED = 'archived'

    ALL = [DRAFT, PUBLISHED, HIDDEN, ARCHIVED].freeze
  end

  alias_attribute :always_present_title, :title

  belongs_to :user, required: true
  belongs_to :author, class_name: 'User', foreign_key: 'user_id', required: true # alias
  belongs_to :channel, required: true
  belongs_to :organization

  has_one :cover, class_name: 'Blog::PostCover', foreign_key: 'blog_post_id', inverse_of: :post, dependent: :destroy
  belongs_to :featured_link_preview, class_name: 'LinkPreview'

  has_many :post_comments, class_name: 'Blog::Comment', foreign_key: 'blog_post_id', inverse_of: :post, dependent: :destroy
  has_many :comments, class_name: 'Blog::Comment', as: :commentable
  has_many :blog_posts_link_previews, class_name: 'Blog::PostsLinkPreviews', foreign_key: 'blog_post_id'
  has_many :link_previews, through: :blog_posts_link_previews, source: :link_preview
  has_many :blog_images, class_name: 'Blog::Image', foreign_key: 'blog_post_id', dependent: :destroy

  accepts_nested_attributes_for :cover

  before_validation :set_organization, if: :channel_id_changed?
  before_validation :set_body_preview, if: :body_changed?
  before_validation :trim_title, if: ->(post) { post.title.length > 72 }
  before_validation :sanitize_body, if: :body_changed?

  before_save :sanitize_title, if: :title_changed?
  after_create :update_short_urls
  # after_create :log_activity

  after_commit :update_published_at
  after_commit :save_link_previews, if: :saved_change_to_body?
  after_commit :cable_update_notifications
  after_commit :notify_mentioned_users

  validates :channel_id, inclusion: { in: ->(post) { post.user.present? ? post.user.all_channels.pluck(:id) : [] } }
  validates :title, presence: true, length: { within: 3..72 }
  validates :status, presence: true, inclusion: { in: Statuses::ALL }
  validates :organization_id, presence: true
  validates :organization_id, inclusion: { in: ->(post) { [post.channel.organization_id] } }, if: :channel_id?
  validates :slug, presence: true, uniqueness: { scope: :organization, message: 'should be unique per organization' }
  validate :valid_featured_link_preview?, if: :featured_link_preview_id_changed?
  validate :valid_body?

  scope :draft, -> { where(status: Statuses::DRAFT) }
  scope :published, -> { where(status: Statuses::PUBLISHED) }
  scope :hidden, -> { where(status: Statuses::HIDDEN) }
  scope :archived, -> { where(status: Statuses::ARCHIVED) }
  scope :not_archived, -> { where.not(status: Statuses::ARCHIVED) }
  scope :editable_by_user, lambda { |user|
    if user.blank? || user.current_organization.blank? || (channels_with_credentials = user.organization_channels_with_credentials(user.current_organization, %i[manage_blog_post moderate_blog_post]).pluck(:id)).blank?
      none
    else
      where(channel_id: channels_with_credentials)
    end
  }

  Statuses::ALL.each do |const|
    define_method("status_#{const}?") { status == const }
    define_method("status_#{const}!") do
      update_attribute(:status, const)
    end
  end

  def is_fake?
    channel&.is_fake? || user&.fake
  end

  def main_image
    @main_image ||= (cover || build_cover)
  end

  def image_url
    @image_url ||= main_image.image_url
  end

  alias_method :share_image_url, :image_url

  def share_description
    body_preview
  end

  def share_title
    title
  end

  def image_thumbnail_preview_url
    @image_thumbnail_preview_url ||= main_image.image_thumbnail_preview_url
  end

  def image_thumbnail_url
    @image_thumbnail_url ||= main_image.image_thumbnail_url
  end

  alias_method :logo_url, :image_thumbnail_url

  def image_medium_url
    @image_medium_url ||= main_image.image_medium_url
  end

  alias_method :cover_url, :image_medium_url

  def image_large_url
    @image_large_url ||= main_image.image_large_url
  end

  def update_comments_count
    return 0 if destroyed?

    count = post_comments.count
    update_attribute(:comments_count, count)
    count
  end

  def should_generate_new_friendly_id?
    new_record? || slug.blank? || organization_id_changed?
  end

  def save_link_previews
    parser = Html::Parser.new(body)
    parser.get_link_previews.each do |link_preview|
      blog_posts_link_previews.find_or_create_by(link_preview_id: link_preview.id)
    end
  end

  def relative_path
    @relative_path ||= "/o/#{organization.slug}/community/#{friendly_id ? friendly_id : slug}"
  end

  def as_json
    {
      id: id,
      organization_id: organization_id,
      channel_id: channel_id,
      user_id: user_id,
      relative_path: relative_path,
      slug: slug,
      title: title,
      body_preview: body_preview,
      status: status,
      comments_count: comments_count,
      logo_url: logo_url,
      cover_url: cover_url,
      tag_list: tag_list,
      views_count: views_count,
      likes_count: likes_count,
      featured_link_preview_id: featured_link_preview_id,
      hide_author: hide_author,
      created_at: created_at.utc.to_fs(:rfc3339),
      updated_at: updated_at.utc.to_fs(:rfc3339),
      channel: {
        id: channel_id,
        title: channel&.title,
        organization_id: channel&.organization_id,
        relative_path: channel&.relative_path,
        logo_url: channel&.logo_url,
        short_url: channel&.short_url
      },
      user: {
        id: user&.id,
        public_display_name: user&.public_display_name,
        avatar_url: user&.avatar_url,
        relative_path: user&.relative_path
      },
      organization: {
        id: organization.id,
        name: organization.name,
        website_url: organization.website_url,
        relative_path: organization.relative_path,
        short_url: organization.short_url,
        logo_url: organization.logo_url
      }
    }
  end

  alias_method :organizer, :user

  def clear_body
    CGI.unescapeHTML(Sanitize.clean(body.to_s)).strip
  end

  def notify_mentioned_users
    return unless status_published? && (@_new_record_before_last_commit || previous_changes[:status].present?)

    mentioned_user_ids.each do |mentioned_user_id|
      ::BlogMailer.new_mention_in_post(id, mentioned_user_id).present? # .deliver_later
    end
  end

  private

  def trim_title
    self.title = title.to_s.first(72)&.strip
  end

  def sanitize_title
    self.title = CGI.unescapeHTML(Sanitize.clean(title.to_s))
  end

  def sanitize_body
    self.body = Html::Parser.new(body).process_link_previews.remove_scripts.to_s
  end

  def set_body_preview
    body_plain = clear_body.gsub(/(&nbsp;|\s)+/, ' ')
    self.body_preview = CGI.unescapeHTML(Sanitize.clean((body_plain.to_s.length < 256) ? body_plain.to_s : "#{body_plain.to_s.first(255).strip}…"))
  end

  def log_activity
    log_daily_activity(:create, owner: user)
  end

  def set_organization
    self.organization = channel&.organization
  end

  def valid_featured_link_preview?
    unless LinkPreview.exists?(id: featured_link_preview_id) || featured_link_preview_id.nil?
      errors.add(:featured_link_preview_id, "##{featured_link_preview_id} does not exist")
    end
  end

  def valid_body?
    if body.exclude?('<img') && body.exclude?('<div class="morphx__embed') && (body.empty? || clear_body.length < 6)
      errors.add(:body, 'has to contain at least 6 characters')
    end
  end

  def cable_update_notifications
    if saved_change_to_status?
      OrganizationBlogChannel.broadcast_to organization, event: 'post_status_updated', data: { id: id, status: status }
      if status_published?
        OrganizationBlogChannel.broadcast_to(organization,
                                             event: 'post_published',
                                             data: as_json)
      end
    end

    if saved_change_to_title?
      OrganizationBlogChannel.broadcast_to organization, event: 'post_title_updated', data: { id: id, title: title }
    end
    if saved_change_to_slug?
      OrganizationBlogChannel.broadcast_to organization, event: 'post_slug_updated',
                                                         data: { id: id, slug: slug, relative_path: relative_path }
    end
    if status_published?
      if saved_change_to_body?
        OrganizationBlogChannel.broadcast_to organization, event: 'post_body_updated', data: { id: id, body: body }
      end
      if saved_change_to_body_preview?
        OrganizationBlogChannel.broadcast_to organization, event: 'post_body_preview_updated',
                                                           data: { id: id, body_preview: body_preview }
      end
      if saved_change_to_featured_link_preview_id?
        OrganizationBlogChannel.broadcast_to organization, event: 'post_link_preview_updated',
                                                           data: { id: id, link_preview_id: featured_link_preview_id }
      end
    end
  end

  def update_published_at
    touch(:published_at) if saved_change_to_status? && status_published? && published_at.nil?
  end
end
