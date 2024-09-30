# frozen_string_literal: true
class Blog::Comment < Blog::ApplicationRecord
  include ModelConcerns::Trackable
  include ModelConcerns::ActiveModel::Extensions
  include ModelConcerns::Shared::Blog::HasMentions

  class << self
    def visible_for_user(user = nil)
      if Rails.application.credentials.global[:enterprise]
        visible_for_user_enterprise(user)
      else
        visible_for_user_marketplace(user)
      end
    end

    def visible_for_user_enterprise(user = nil)
      return joins(:post).none if !user.is_a?(User) || !user.persisted?
      return joins(:post).where(nil) if user.service_admin? || user.platform_owner?

      channels_with_manage_credentials = user.all_channels_with_credentials(%i[manage_blog_post
                                                                               moderate_blog_post]).pluck(:id)
      channels_with_member_credentials = user.all_channels_with_credentials(::AccessManagement::Credential::Codes::VIEW_CONTENT).pluck(:id)
      return joins(:post).none if channels_with_manage_credentials.blank? && channels_with_member_credentials.blank?

      joins(:post).where(%{blog_posts.channel_id IN (:manage_channel_ids) OR blog_posts.status = :published AND blog_posts.channel_id IN (:member_channel_ids)},
                         { published: ::Blog::Post::Statuses::PUBLISHED,
                           manage_channel_ids: channels_with_manage_credentials,
                           member_channel_ids: channels_with_member_credentials })
    end

    def visible_for_user_marketplace(user = nil)
      return joins(:post).where(blog_posts: { status: ::Blog::Post::Statuses::PUBLISHED }) if !user.is_a?(User) || !user.persisted?
      return joins(:post).where(nil) if user.service_admin? || user.platform_owner?

      channels_with_manage_credentials = user.all_channels_with_credentials(%i[manage_blog_post
                                                                               moderate_blog_post]).pluck(:id)
      return joins(:post).where(blog_posts: { status: ::Blog::Post::Statuses::PUBLISHED }) if channels_with_manage_credentials.blank?

      joins(:post).where(%{blog_posts.status = :published OR blog_posts.channel_id IN (:channel_ids)},
                         published: ::Blog::Post::Statuses::PUBLISHED, channel_ids: channels_with_manage_credentials)
    end
  end

  belongs_to :user, optional: false
  belongs_to :author, class_name: 'User', foreign_key: 'user_id', optional: false # alias
  belongs_to :post, class_name: 'Blog::Post', foreign_key: 'blog_post_id', inverse_of: :post_comments, optional: false
  belongs_to :commentable, polymorphic: true, optional: false
  belongs_to :featured_link_preview, class_name: 'LinkPreview'

  has_many :comments, class_name: 'Blog::Comment', as: :commentable
  has_many :blog_comments_link_previews, class_name: 'Blog::CommentsLinkPreviews', foreign_key: 'blog_comment_id'
  has_many :link_previews, through: :blog_comments_link_previews, source: :link_preview

  before_validation :set_post, if: :commentable_id_changed?
  before_validation :sanitize_body

  validates :body, presence: true
  validate :valid_body_text_length?
  validate :valid_featured_link_preview?, if: :featured_link_preview_id_changed?

  after_create :notify_commentable_user, unless: ->(comment) { comment.user_id == comment.commentable.user_id }
  # after_create :log_activity
  after_create :update_commentable_comments_count
  after_destroy :update_commentable_comments_count
  after_commit :save_link_previews, if: :saved_change_to_body?
  after_commit :notify_mentioned_users, on: :create

  def body_text
    @body_text ||= Nokogiri::HTML.parse(body).inner_text
  end

  def notify_mentioned_users
    return unless post.status_published?

    mentioned_user_ids.each do |mentioned_user_id|
      ::BlogMailer.new_mention_in_comment(id, mentioned_user_id).present? # .deliver_later
    end
  end

  def update_comments_count
    return 0 if destroyed?

    count = comments.count
    update_attribute(:comments_count, count)
    count
  end

  private

  def set_post
    case commentable_type
    when 'Blog::Post'
      self.post = commentable
    when 'Blog::Comment'
      self.post = commentable.post
    end
  end

  def notify_commentable_user
    data = {
      comment: {
        id: id,
        body_preview: ((body.length < 33) ? body : "#{body.first(32).strip}…")
      },
      user: {
        id: user_id,
        public_display_name: user.public_display_name,
        avatar_url: user.avatar_url,
        relative_path: user.relative_path
      },
      post: {
        id: post.id,
        title: post.title
      },
      commentable: {
        id: commentable_id,
        type: commentable_type,
        body_preview: ((commentable.body.length < 33) ? commentable.body : "#{commentable.body.first(32).strip}…")
      }
    }
    UsersChannel.broadcast_to commentable.user, event: 'new-blog-comment', data: data
  end

  def log_activity
    post.log_daily_activity(:comment, owner: user)
  end

  def update_commentable_comments_count
    post.update_comments_count unless post.blank? || post.destroyed?

    return if commentable_type == 'Blog::Post'

    commentable.update_comments_count if commentable.present?
  end

  def sanitize_body
    self.body = Html::Parser.new(body).process_link_previews.remove_scripts.to_s
  end

  def save_link_previews
    parser = Html::Parser.new(body)
    parser.get_link_previews.each do |link_preview|
      blog_comments_link_previews.find_or_create_by(link_preview_id: link_preview.id)
    end
  end

  def valid_featured_link_preview?
    unless LinkPreview.exists?(id: featured_link_preview_id)
      errors.add(:featured_link_preview_id, "##{featured_link_preview_id} does not exist")
    end
  end

  def valid_body_text_length?
    length = body_text.length
    errors.add(:body, 'length must be greated than 1') if length <= 1
    errors.add(:body, 'length must be less than 600') if length > 600
  end
end
