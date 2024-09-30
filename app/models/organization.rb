# frozen_string_literal: true
class Organization < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions
  include ModelConcerns::ActsAsFollowable
  include ModelConcerns::HasShortUrl
  include ModelConcerns::Organization::Authenticate
  include ModelConcerns::Organization::HasChannels
  include ModelConcerns::Organization::HasCredentials
  include ModelConcerns::Organization::HasCreators
  include ModelConcerns::Organization::HasFfmpegserviceAccounts
  include ModelConcerns::Organization::HasServiceSubscription
  include ModelConcerns::Trackable
  include ModelConcerns::Shared::Viewable
  include ModelConcerns::Shared::HasPromoWeight

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged]

  acts_as_messageable

  include ModelConcerns::CanWrapExternalUrls
  wrap_external_urls :description

  RATYRATE_KEY = 'cumulative_valuation'
  ratyrate_rateable(RATYRATE_KEY)

  belongs_to :user, inverse_of: :organization, touch: true
  belongs_to :industry

  has_many :social_links, as: :entity, dependent: :destroy

  has_many :child_users, class_name: 'User', inverse_of: :parent_organization, foreign_key: 'parent_organization_id'

  has_many :organization_memberships, dependent: :destroy
  has_many :organization_memberships_participants, -> { where(membership_type: :participant) }, class_name: 'OrganizationMembership'
  has_many :organization_memberships_guests, -> { where(membership_type: :guest) }, class_name: 'OrganizationMembership'
  has_many :organization_memberships_active, lambda {
                                               participants.where(status: OrganizationMembership::Statuses::ACTIVE)
                                             }, class_name: 'OrganizationMembership'
  has_many :employees, through: :organization_memberships_active, source: :user
  has_many :groups_members, through: :organization_memberships_active, source: :groups_members
  has_many :all_groups_members, through: :organization_memberships_participants, source: :groups_members,
                                class_name: 'AccessManagement::GroupsMember'
  has_many :channels, dependent: :destroy
  has_many :studios, dependent: :destroy
  has_many :studio_rooms, through: :studios
  has_many :channel_invited_presenterships, through: :channels
  has_many :sessions, through: :channels
  has_many :stream_previews
  has_many :blog_posts, class_name: 'Blog::Post'
  has_many :blog_images, class_name: 'Blog::Image', dependent: :destroy
  has_many :service_subscriptions, through: :user, source: :service_subscriptions
  has_many :groups, class_name: 'AccessManagement::Group'
  has_many :lists, class_name: 'Shop::List', dependent: :destroy
  has_many :products, class_name: 'Shop::Product', foreign_key: :organization_uuid, primary_key: :uuid, inverse_of: :organization, dependent: :destroy
  has_many :free_plans, through: :channels
  has_many :partner_plans, through: :free_plans
  has_many :free_subscriptions, through: :free_plans
  has_many :partner_subscriptions, through: :partner_plans
  has_many :storage_records, class_name: 'Storage::Record', foreign_key: :organization_uuid, primary_key: :uuid, inverse_of: :organization
  has_many :poll_templates, class_name: 'Poll::Template::Poll', dependent: :destroy

  has_one :cover, class_name: 'OrganizationCover', dependent: :destroy
  has_one :logo, class_name: 'OrganizationLogo', dependent: :destroy
  has_one :mind_body_db_site, class_name: 'MindBodyDb::Site', dependent: :destroy
  has_one :company_setting, dependent: :destroy

  accepts_nested_attributes_for :employees, allow_destroy: true
  accepts_nested_attributes_for :cover
  accepts_nested_attributes_for :logo, allow_destroy: true

  validates :stop_no_stream_sessions, inclusion: { in: ((5..30).to_a << 0) }
  # validates :description, :tagline, presence: true
  # validates :industry_id, presence: true

  accepts_nested_attributes_for :social_links, reject_if: proc { |attributes|
                                                            attributes['link'].blank? and attributes['id'].blank?
                                                          }, allow_destroy: true

  # after_create :assign_channels
  after_create :update_short_urls

  after_commit :recreate_urls, on: :update, if: proc { |obj| obj.slug.present? && obj.saved_change_to_slug? }
  after_commit :touch_channels
  after_commit :set_as_current, on: :create

  delegate :ffmpegservice_transcode, to: :user

  enum multiroom_status: {
    default: 0,
    enabled: 1,
    disabled: 2
  }

  scope :fake, -> { where(fake: true) }
  scope :not_fake, -> { where(fake: false) }
  scope :for_home_page, -> { where(show_on_home: true) }

  multiroom_statuses.keys.each do |const|
    define_method("multiroom_status_#{const}?") { multiroom_status == const }
    define_method("multiroom_status_#{const}!") { update_attribute(:multiroom_status, const) }
  end

  def revenue_percent
    if Rails.application.credentials.global.dig(:service_subscriptions, :enabled) && user.service_subscription.present?
      user.service_subscription&.plan_package&.feature_parameters&.by_code(:split_revenue_percent)&.first&.value&.to_i || 100
    else
      user.profit_margin_percent.to_i
    end
  end

  def active_subscription_or_split_revenue?
    !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) ||
      split_revenue_plan || user.service_subscription.present?
  end

  def split_revenue?
    !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) || split_revenue_plan
  end

  def members_data
    memberships = organization_memberships.includes(:user)
    data = []
    memberships.each do |m|
      data << m.user.user_data.merge({ id: m.id, role: m.role, user_id: m.user_id })
    end
    data
  end

  def formatted_website_url
    u = URI.parse(website_url.strip)
    u.scheme.blank? ? "https://#{website_url.strip}" : website_url
  rescue StandardError
    website_url
  end

  # NOTE: this method is used in messages/_form
  def public_display_name
    name
  end

  alias_method :share_title, :public_display_name
  alias_attribute :title, :name

  def share_description
    description
  end

  def organizer
    user
  end

  # @return [User]
  def presenter_users
    membership = User.select(:id).where("users.id IN(#{organization_memberships.select('organization_memberships.user_id').where(role: OrganizationMembership::Roles::PRESENTER).to_sql})").to_sql
    creators = User.select(:id).joins(:presenter).where("presenters.id IN(#{channel_invited_presenterships.select('channel_invited_presenterships.presenter_id').where(status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED).to_sql})").to_sql

    User.where("users.id IN((#{membership})UNION(#{creators}))").distinct
  end

  # @return [ActsAsTaggableOn]
  def tags
    @tags ||= ActsAsTaggableOn::Tag.where("id IN(SELECT tag_id FROM taggings WHERE taggable_type = 'Channel' AND context = 'tags' AND taggable_id IN(SELECT id FROM channels WHERE organization_id = #{id}))")
  end

  # orgs are not rated directly, only as cumulative ratings of their channels/sessions
  # this code is needed for displaying "stars" helper
  # see https://github.com/muratguzel/letsrate/blob/master/lib/letsrate/helpers.rb#L12
  # NOTE: result of this method has to respond to #avg call to comply with rating_for helper
  def average(dimension = nil)
    # passed dimension param is ignore because we only use one(Session::RateKeys::QUALITY_OF_CONTENT) - that's just
    # for complying to code contract
    OpenStruct.new.tap do |ostruct|
      ostruct.avg = Rails.cache.fetch("average/#{cache_key}") do
        averages = channels.collect { |channel| channel.average(dimension) }.keep_if { |av| !av.avg.zero? }

        averages.blank? ? 0 : (averages.collect(&:avg).reduce(:+) / averages.size)
      end
    end
  end

  def raters_quantity
    Rails.cache.fetch("raters_quantity/#{cache_key}") { channels.sum(&:raters_count) }
  end

  def small_logo_url
    (logo || build_logo).small_url
  end

  def logo_url
    (logo || build_logo).medium_url
  end

  alias_method :share_image_url, :logo_url

  def cover_url
    (cover || build_cover).medium_url
  end

  alias_method :poster_url, :cover_url

  def medium_logo_url
    (logo || build_logo).medium_url
  end

  def relative_path
    friendly_id ? "/#{friendly_id}" :
      if changed?
        raise("organization #{id} does not have #friendly_id. name: #{name}")
      else
        save
        result = slug

        if result.present?
          Airbrake.notify(RuntimeError.new('just fixed blank slug for organization'),
                          parameters: {
                            organization: inspect
                          })
          slug
        else
          raise(" __ organization #{id} does not have #friendly_id. name: #{name}")
        end
      end
  end

  # utm_params are needed for tracking visits from email links
  # @see UTM dependency
  # refc_user for sharing
  # @see SharingHelper, SharedControllerHelper
  def absolute_path(utm_params = nil, refc_user = nil)
    request_protocol = ActionMailer::Base.default_url_options[:protocol] || 'http://'
    host = ActionMailer::Base.default_url_options[:host] or raise 'cant get HOST'

    result = if accessible_via_subdomain?
               "#{request_protocol}#{friendly_id}.#{host}/"
             else
               "#{request_protocol}#{host}#{relative_path}"
             end
    params = []
    params << utm_params if utm_params
    params << "refc=#{refc_user.my_referral_code_text}" if refc_user.is_a?(User)
    result += "?#{params.join('&')}" unless params.empty?
    result
  end

  def publicly_visibile_to_general_audience
    channels.where('channels.status = ? AND channels.archived_at IS NULL AND channels.listed_at IS NOT NULL',
                   Channel::Statuses::APPROVED)
  end

  private def check_slug_presence
    friendly_id ? "/#{friendly_id}" :
      if changed?
        raise("organization #{id} does not have #friendly_id. name: #{name}")
      else
        save
        result = slug

        if result.present?
          Airbrake.notify(RuntimeError.new('just fixed blank slug for organization'),
                          parameters: {
                            organization: inspect
                          })
          slug
        else
          raise(" __ organization #{id} does not have #friendly_id. name: #{name}")
        end
      end
  end

  def preview_share_relative_path
    "#{relative_path}/preview_share"
  end

  # TODO: - get rid of it and rename all always_present_title methods
  def always_present_title
    name
  end

  # TODO: I don't like it...
  def main_image
    @main_image ||= channels.joins(:cover).limit(1).first.try(:main_image) || ChannelImage.new(is_main: true)
  end

  def pinterest_share_preview_image_url
    @pinterest_share_preview_image_url ||= main_image.image_gallery_url
  end

  def reviews_with_comment
    @reviews_with_comment ||= channels.collect(&:reviews_with_comment).flatten
  end

  def reviews(_dimension = 'quality_of_content')
    Review.unscoped
          .joins("LEFT JOIN sessions ON reviews.commentable_type = 'Session' AND reviews.commentable_id = sessions.id")
          .joins("LEFT JOIN recordings ON reviews.commentable_type = 'Recording' AND reviews.commentable_id = recordings.id")
          .joins('JOIN channels ON sessions.channel_id = channels.id OR recordings.channel_id = channels.id')
          .where("reviews.overall_experience_comment IS NOT NULL AND reviews.overall_experience_comment != ''")
          .where(channels: { organization_id: id }, sessions: { cancelled_at: nil }, recordings: { deleted_at: nil })
          .where.not(sessions: { private: true })
          .distinct(reviews: :id)
  end

  def comments
    Comment.unscoped
           .joins("LEFT JOIN sessions ON comments.commentable_type = 'Session' AND comments.commentable_id = sessions.id")
           .joins("LEFT JOIN recordings ON comments.commentable_type = 'Recording' AND comments.commentable_id = recordings.id")
           .joins('JOIN channels ON sessions.channel_id = channels.id OR recordings.channel_id = channels.id')
           .where(channels: { organization_id: id }, sessions: { cancelled_at: nil }, recordings: { deleted_at: nil })
           .where.not(sessions: { private: true })
           .distinct(comments: :id)
  end

  def jwt_secret
    Digest::MD5.hexdigest(secret_key + Rails.application.secret_key_base)
  end

  def integration_jwt_secret
    Digest::MD5.hexdigest(secret_key)
  end

  def recreate_urls
    update_short_urls
    OrganizationJobs::SlugUpdated.perform_async(id)
  end

  def ready_for_wa?
    has_approved_channels?
  end

  def multiroom_available?
    channels.approved.listed.not_archived.count.positive? && (split_revenue? || user.service_subscription&.plan_package&.is_multi_room?)
  end

  def multiroom_enabled?
    case multiroom_status
    when 'enabled'
      return true
    when 'disabled'
      return false
    when 'default'
      return multiroom_available?
    end
  end

  def custom_logo_url
    company_setting&.logo_image&.url
  end

  def custom_css
    company_setting&.custom_styles
  end

  def logo_link(user = nil)
    Rails.cache.fetch("organization/#{cache_key}/#{__method__}/#{user&.cache_key}") do
      link = nil
      if company_setting&.logo_channel_link && (ch = default_user_channel(user))
        link = ch.relative_path
      end

      link || '/'
    end
  end

  private

  def touch_channels
    channels.touch_all
  end

  def slug_candidates
    [
      name,
      [name, id]
    ]
  end

  # Task 2657
  # will call ensure_belongs_to_one_entity
  def assign_channels
    return unless user.presenter

    existing_channels = user.presenter.channels
    existing_channels.update_all(organization_id: id, presenter_id: nil)
  end

  def should_generate_new_friendly_id?
    new_record? || slug.blank? || name_changed?
  end

  def set_as_current
    user.update(current_organization_id: id)
  end
end
