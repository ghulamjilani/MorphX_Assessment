# frozen_string_literal: true
class Channel < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActsAsFollowable
  include ModelConcerns::HasShortUrl
  include ModelConcerns::Channel::PgSearchable
  include ModelConcerns::Trackable
  include ModelConcerns::ActiveModel::Extensions
  include ModelConcerns::Shared::Viewable
  include ModelConcerns::Im::HasConversation
  include ModelConcerns::Shared::HasPromoWeight
  include ModelConcerns::Shared::HasLists

  extend FriendlyId

  class << self
    def visible_for_user(user = nil)
      if Rails.application.credentials.global[:enterprise]
        visible_for_user_enterprise(user)
      else
        visible_for_user_marketplace(user)
      end.not_archived
    end

    def visible_for_user_enterprise(user = nil)
      return none if !user.is_a?(User) || !user.persisted?
      return where(nil) if user.service_admin? || user.platform_owner?

      channel_ids = user.all_channels_with_credentials([:view_content]).listed.pluck(:id)
      channel_ids += user.all_channels_with_credentials([:edit_channel]).pluck(:id)
      where(id: channel_ids)
    end

    def visible_for_user_marketplace(user = nil)
      return approved.listed.not_fake if !user.is_a?(User) || !user.persisted?
      return where(nil) if user.service_admin? || user.platform_owner?

      channel_ids = user.all_channels_with_credentials([:edit_channel]).pluck(:id)
      organization_ids = user.organization_memberships_active.pluck :organization_id
      where(
        'channels.listed_at IS NOT NULL and channels.fake IS NOT TRUE OR channels.id IN (:channel_ids) OR (channels.listed_at IS NOT NULL AND channels.organization_id IN (:organization_ids))', {
          channel_ids: channel_ids, organization_ids: organization_ids
        }
      )
    end
  end

  belongs_to :category, class_name: 'ChannelCategory'
  belongs_to :channel_type
  belongs_to :organization
  belongs_to :presenter

  has_one :user, through: :organization
  has_one :cover, -> { where(is_main: true) }, class_name: 'ChannelImage', dependent: :destroy
  has_one :logo, class_name: 'ChannelLogo', dependent: :destroy
  has_one :subscription, -> { where(enabled: true) }
  has_many :booking_slots, class_name: 'Booking::BookingSlot', dependent: :destroy, inverse_of: :channel
  has_many :sessions, dependent: :destroy, inverse_of: :channel
  has_many :free_plans, foreign_key: :channel_uuid, primary_key: :uuid, dependent: :destroy
  has_many :free_subscriptions, through: :free_plans do
    def with_features(*enabled_features)
      free_plan_where = Array(enabled_features).index_with(true)
      where(free_plans: free_plan_where)
    end
  end
  has_many :partner_plans, through: :free_plans
  has_many :partner_subscriptions, through: :partner_plans
  has_many :subscriptions, dependent: :destroy, inverse_of: :channel
  has_many :images, -> { where(is_main: false) }, class_name: 'ChannelImage', dependent: :destroy
  has_many :channel_links, dependent: :destroy
  has_many :channel_invited_presenterships
  has_many :channel_invited_presenterships_accepted, lambda {
                                                       where(status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED)
                                                     }, class_name: 'ChannelInvitedPresentership'
  has_many :presenters, through: :channel_invited_presenterships_accepted, source: :presenter
  has_many :users, through: :presenters, source: :user
  has_many :recordings, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :videos, through: :sessions, source: :records
  has_many :blog_posts, class_name: 'Blog::Post', dependent: :destroy
  has_many :opt_in_modals, class_name: 'MarketingTools::OptInModal', foreign_key: :channel_uuid, primary_key: :uuid, dependent: :destroy
  has_many :polls, class_name: 'Poll::Poll', as: :model, dependent: :destroy

  accepts_nested_attributes_for :images, allow_destroy: true
  accepts_nested_attributes_for :cover
  accepts_nested_attributes_for :logo, allow_destroy: true
  accepts_nested_attributes_for :channel_links, allow_destroy: true

  # before_save :ensure_belongs_to_one_entity
  before_validation { self.title = title.to_s.strip }
  # because state_machine is abandoned and with Rails 4.2 :initial option is simply ignored
  after_initialize :set_initial_status
  after_initialize :set_initial_type
  before_validation :sanitize_description, if: :description_changed?
  before_validation :check_whether_was_rejected
  after_create do
    SubmittedForReviewStatusCheck.perform_at(1.hour.from_now, id)
  end
  after_create :update_short_urls
  after_update :notify_admins_about_changes, if: proc { |obj|
                                                   obj.approved? && obj.send(:changed_notifiable_attrs).present?
                                                 }
  after_update :notify_organizer, if: :saved_change_to_status?
  after_update :notify_im_conversation_disabled, if: proc { |channel| channel.saved_change_to_im_conversation_enabled? && !channel.im_conversation_enabled? }

  after_save :list_immediately, if: :just_got_approved?
  after_save :send_invites, if: :got_approved?
  after_save :archive_subscription, if: proc { |obj| obj.archived_at.present? && obj.saved_change_to_archived_at? }
  after_save :assign_im_conversation, if: proc { |channel| channel.im_conversation_enabled? && (channel.instance_variable_get(:@_new_record_before_last_commit) || channel.saved_change_to_im_conversation_enabled?) }
  after_commit :check_is_default
  after_commit :touch_sessions, if: lambda { |o|
                                      (o.saved_change_to_description? or o.saved_change_to_title? or o.saved_change_to_tag_list? or o.saved_change_to_status? or o.saved_change_to_listed_at?) && !o.saved_change_to_slug?
                                    } # save change to slug already triggers update for each session
  after_commit :clear_user_listed_channels_cache, if: :saved_change_to_listed_at?
  after_commit :user_reindex, if: lambda { |o|
                                    o.saved_change_to_status? or o.saved_change_to_listed_at? or o.saved_change_to_archived_at?
                                  }, on: :update
  after_commit :clear_fields, if: :approved?
  after_commit :recreate_urls, on: :update, if: proc { |obj| obj.slug.present? && obj.saved_change_to_slug? }

  validates :rejection_reason, presence: true, if: :rejected?
  validates :category, :status, :channel_type, presence: true
  validates :title, length: { within: 5..72 }
  validates :channel_location, length: { within: 3..80 }, allow_blank: true
  # validates :approximate_start_date, presence: true, length: { within: 3..30 }, on: :channel_controller
  validates :tag_list, length: {
    minimum: 1,
    too_short: 'must have at least %{count} tags',
    too_long: 'must have at most %{count} tags',
    maximum: 20
  }, on: :channel_controller

  validate :description_text_length_validation, on: :channel_controller
  validate :maximum_channel_images_compliance, on: :channel_controller
  validate :max_channel_links, on: :channel_controller
  validate :archived_skip_coming_soon, on: :channel_controller
  validate :not_archived_uniq_title, on: :create

  alias_method :toggle_subscribe_relative_path, :toggle_follow_relative_path

  acts_as_votable # for likes
  friendly_id :friendly_id_slug_candidate, use: %i[history slugged], sequence_separator: '/'
  acts_as_ordered_taggable_on :tags

  RATYRATE_KEY = 'cumulative_valuation'
  NOTIFY_ABOUT_UPDATES_IN_FIELDS = %w[category_id channel_location channel_type_id description organization_id
                                      presenter_id title].freeze
  SHARE_IMAGE_WIDTH = 1170
  SHARE_IMAGE_HEIGHT = 500

  ratyrate_rateable(RATYRATE_KEY)
  state_machine :status, initial: :draft do
    after_transition any => :pending_review do |channel, _transition|
      ChannelMailer.pending_channel_appeared(channel.id).deliver_later
    end

    event :auto_approve do
      transition %i[draft pending_review] => :approved
    end

    event :approve do
      transition [:pending_review] => :approved
    end

    event :submit_for_review do
      transition %i[draft rejected] => :pending_review
    end

    event :reject do
      transition %i[draft pending_review approved] => :rejected
    end
  end

  module Statuses
    DRAFT = 'draft'
    PENDING_REVIEW = 'pending_review'

    APPROVED = 'approved'
    REJECTED = 'rejected'
    ALL = [DRAFT, PENDING_REVIEW, APPROVED, REJECTED].freeze
  end

  module Constants
    COLLECT_APPROXIMATE_DURATIONS = ['30 mins', '60 mins', '90 mins', '120 mins', '150 mins', '180 mins'].freeze

    module YouMayAlsoLike
      VISIBLE = 'youmayalsolikevisible'
      HIDDEN = 'youmayalsolikehidden'

      ALL = [VISIBLE, HIDDEN].freeze
    end
  end

  scope :listed, -> { where.not(listed_at: nil) }
  scope :approved, -> { where(status: Statuses::APPROVED) }
  scope :pending_review, -> { where(status: Statuses::PENDING_REVIEW) }
  scope :rejected, -> { where(status: Statuses::REJECTED) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :not_archived, -> { where(archived_at: nil) }
  scope :draft, -> { where(status: Statuses::DRAFT) }
  scope :fake, -> { where(fake: true) }
  scope :not_fake, -> { where(fake: false) }
  scope :for_home_page, -> { where(show_on_home: true) }
  scope :featured, -> { where.not(featured_at: nil) }
  scope :with_user, lambda {
    joins('LEFT OUTER JOIN presenters AS owners ON owners.id = channels.presenter_id')
      .joins('LEFT OUTER JOIN organizations ON organizations.id = channels.organization_id')
      .joins('INNER JOIN users ON users.id = owners.user_id OR users.id = organizations.user_id')
  }

  scope :publicly_visibile_to_general_audience, -> { approved.not_archived.listed.not_fake }
  scope :without_sessions, -> { where('channels.id NOT IN(SELECT sessions.channel_id FROM sessions)') }

  def live_sessions_for(user)
    sessions.for_user_with_age(user).visible_for(user).not_archived.not_cancelled.not_finished.published
            .where(stopped_at: nil).order(start_at: :asc)
  end

  def count_live_sessions_for(user = nil)
    if user
      sessions.select('sessions.*').distinct
              .joins(:channel)
              .joins('LEFT OUTER JOIN presenters AS owners ON channels.presenter_id = owners.id')
              .joins('LEFT OUTER JOIN organizations ON organizations.id = channels.organization_id')
              .joins("LEFT OUTER JOIN channel_invited_presenterships ON channel_invited_presenterships.channel_id = channels.id AND channel_invited_presenterships.status = 'accepted'")
              .joins('LEFT OUTER JOIN presenters AS channel_members ON channel_invited_presenterships.presenter_id = channel_members.id')
              .joins('LEFT OUTER JOIN livestreamers ON sessions.id = livestreamers.session_id')
              .joins('LEFT OUTER JOIN participants AS livestream_participants ON livestreamers.participant_id = livestream_participants.id')
              .joins('LEFT OUTER JOIN session_participations ON sessions.id = session_participations.session_id')
              .joins('LEFT OUTER JOIN participants ON session_participations.participant_id = participants.id')
              .joins('LEFT OUTER JOIN session_co_presenterships ON sessions.id = session_co_presenterships.session_id')
              .joins('LEFT OUTER JOIN presenters AS co_presenters ON session_co_presenterships.presenter_id = co_presenters.id')
              .where('channels.status = ?', Channel::Statuses::APPROVED)
              .where('sessions.private IS FALSE OR (sessions.private IS TRUE AND (participants.user_id = :id OR co_presenters.user_id = :id OR livestream_participants.user_id = :id OR owners.user_id = :id OR channel_members.user_id = :id OR organizations.user_id = :id OR sessions.presenter_id = :presenter_id))', id: user.id, presenter_id: (user.presenter ? user.presenter.id : -1))
    else
      sessions.joins(:channel).is_public.where.not(channels: { listed_at: nil })
    end.joins(presenter: :user).where(channels: { status: :approved, archived_at: nil,
                                                  fake: false }, users: { fake: false }).not_cancelled.not_finished.published.where(stopped_at: nil).count
  end

  def streams
    sessions.not_archived.not_cancelled.not_finished.published.where(stopped_at: nil).order(start_at: :asc)
  end

  def recordings_storage_size
    recordings.select('SUM(recordings.size) as ss')[0].ss.to_d
  end

  def videos_storage_size
    videos.select('SUM(videos.size) as ss')[0].ss.to_d
  end

  def set_initial_status
    self.status ||= :draft
  end

  def set_initial_type
    self.channel_type_id ||= Channel.not_selected_type_id
  end

  def owner_type
    if organization_id
      'company'
    else
      'individual'
    end
  end

  # TODO: stdashulya or Igor check pls
  def replays
    sessions.joins(:room).joins(:records).
      # where(sessions: {presenter_id: presenter_id}).
      where(videos: { status: Video::Statuses::DONE, deleted_at: nil })
            .where(rooms: { vod_is_fully_ready: true }).distinct
  end

  def videos
    Video.joins(:room).joins(%(INNER JOIN sessions ON sessions.id = rooms.abstract_session_id AND rooms.abstract_session_type = 'Session'))
         .where(sessions: { channel_id: id })
         .where(videos: { deleted_at: nil })
         .where(rooms: { vod_is_fully_ready: true }).distinct
  end

  COMING_SOON_NUM = 18

  def self.coming_soon
    results = fetch_channels(limit: COMING_SOON_NUM, display_in_coming_soon_section: true)

    if results.length < COMING_SOON_NUM
      results += fetch_channels(limit: COMING_SOON_NUM - results.length,
                                display_in_coming_soon_section: false,
                                exclude_channel_ids: results.collect(&:id))
    end
    results
  end

  def self.fetch_channels(limit:, display_in_coming_soon_section:, exclude_channel_ids: [])
    publicly_visibile_to_general_audience
      .where.not(id: exclude_channel_ids)
      .where(display_in_coming_soon_section: display_in_coming_soon_section)
      .where('channels.id IN(SELECT channel_id FROM channel_images)')
      .order('channels.created_at DESC')
      .preload(:images)
      .limit(limit)
  end

  private_class_method :fetch_channels

  def self.performance
    where(channel_type_id: performance_type_id)
  end

  def self.performance_type_id
    Rails.cache.fetch('performance_type_id') do
      ChannelType.find_by(description: ChannelType::Descriptions::PERFORMANCE).id
    end
  end

  def self.instructional
    where(channel_type_id: instructional_type_id)
  end

  def self.instructional_type_id
    Rails.cache.fetch('instructional_type_id') do
      ChannelType.find_by(description: ChannelType::Descriptions::INSTRUCTIONAL).id
    end
  end

  def self.social
    where(channel_type_id: social_type_id)
  end

  def self.social_type_id
    Rails.cache.fetch('social_type_id') { ChannelType.find_by(description: ChannelType::Descriptions::SOCIAL).id }
  end

  def self.not_selected
    where(channel_type_id: not_selected_type_id)
  end

  def self.not_selected_type_id
    Rails.cache.fetch('not_selected_type_id') do
      ChannelType.find_by(description: ChannelType::Descriptions::NOT_SELECTED).id
    end
  end

  def presenterships_data
    presenterships = channel_invited_presenterships.includes(presenter: [:user])
    data = []
    presenterships.each do |p|
      data << p.user.user_data.merge({ id: p.id, user_id: p.user.id })
    end
    data
  end

  def presenter_users
    users.where(fake: false, channel_invited_presenterships: { status: :accepted })
  end

  alias_method :subscribers, :user_followers

  def last_subscribers_as_json(limit = 14)
    subscribers.limit(limit).to_json(only: [:id],
                                     methods: %i[has_channels public_display_name avatar_url relative_path])
  end

  def featured
    !!featured_at
  end

  def featured=(value)
    case value
    when '1'
      self.featured_at = Time.now
    when '0'
      self.featured_at = nil
    end
  end

  # @return [User]
  def organizer
    User.find_by(id: organizer_user_id)
  end

  def organizer_user_id
    organization.user_id
  rescue StandardError => e
    Airbrake.notify(e.message,
                    parameters: {
                      message: "Exception in Channel::organizer_user_id: Channel presenter or organization doesn't exist",
                      channel_id: id
                    })
    nil
  end

  def performance_type?
    channel_type.description == ChannelType::Descriptions::PERFORMANCE
  end

  def instructional_type?
    channel_type.description == ChannelType::Descriptions::INSTRUCTIONAL
  end

  def social_type?
    channel_type.description == ChannelType::Descriptions::SOCIAL
  end

  def not_selected_type?
    channel_type.description == ChannelType::Descriptions::NOT_SELECTED
  end

  def toggle_like_relative_path
    "#{relative_path}/toggle_like"
  end

  def likes_cache_key
    "likes/#{self.class.to_s.downcase}/#{id}"
  end

  def likes_count
    Rails.cache.fetch(likes_cache_key) do
      get_likes.count
    end
  end

  # utm_params are needed for tracking visits from email links
  # @see UTM dependency
  # refc_user for sharing
  # @see SharingHelper, SharedControllerHelper
  def absolute_path(utm_params = nil, refc_user = nil)
    request_protocol = ActionMailer::Base.default_url_options[:protocol] || 'http://'
    host = ActionMailer::Base.default_url_options[:host] or raise 'cant get HOST'

    result = "#{request_protocol}#{host}#{relative_path}"
    params = []
    params << utm_params if utm_params
    params << "refc=#{refc_user.my_referral_code_text}" if refc_user.is_a?(User)
    result += "?#{params.join('&')}" unless params.empty?
    result
  end

  def relative_path
    friendly_id ? "/#{friendly_id}" : raise("channel #{id} does not have #friendly_id. title: #{title}")
  end

  def preview_share_relative_path
    "#{relative_path}/preview_share"
  end

  def share_title
    I18n.t('models.channel.share_title', title: title,
                                         service_name: Rails.application.credentials.global[:service_name])
  end

  def list!
    self.listed_at = Time.zone.now
    save!
  end

  def unlist!
    self.listed_at = nil
    save!
  end

  def listed?
    !!listed_at
  end

  # channels are not rated directly, only as cumulative ratings of their sessions
  # this code is needed for displaying "stars" helper
  # see https://github.com/muratguzel/letsrate/blob/master/lib/letsrate/model.rb#L68
  def can_rate?(_user, _dimension = nil)
    false
  end

  def always_present_title
    title
  end

  # channels are not rated directly, only as cumulative ratings of their sessions
  # this code is needed for displaying "stars" helper
  # see https://github.com/muratguzel/letsrate/blob/master/lib/letsrate/helpers.rb#L12
  # NOTE: result of this method has to respond to #avg call to comply with rating_for helper
  def average(_dimension = nil)
    # passed dimension param is ignore because we only use one(Session::RateKeys::QUALITY_OF_CONTENT) - that's just
    # for complying to code contract
    OpenStruct.new.tap do |ostruct|
      ostruct.avg = Rails.cache.fetch("average/#{cache_key}") do
        _sessions = if Rails.env.development?
                      sessions.where(cancelled_at: nil, status: Session::Statuses::PUBLISHED)
                    else
                      sessions.finished.where(cancelled_at: nil, status: Session::Statuses::PUBLISHED)
                    end

        caches = RatingCache.where(cacheable: _sessions,
                                   dimension: [Session::RateKeys::QUALITY_OF_CONTENT,
                                               Session::RateKeys::PRESENTER_PERFORMANCE])
        caches.blank? ? 0 : caches.map { |rc| rc.avg * rc.qty }.reduce(:+) / caches.map(&:qty).reduce(:+)
      end
    end
  end

  def raters_count
    @raters_count ||= Rate.joins('INNER JOIN sessions ON sessions.id = rates.rateable_id')
                          .where('sessions.channel_id = :channel_id AND sessions.cancelled_at IS NULL AND sessions.status = :status', channel_id: id, status: Session::Statuses::PUBLISHED)
                          .where("now() > (sessions.start_at + (INTERVAL '1 minute' * sessions.duration))")
                          .where(rateable_type: 'Session', dimension: [Session::RateKeys::QUALITY_OF_CONTENT,
                                                                       Session::RateKeys::PRESENTER_PERFORMANCE])
                          .count
  end

  def reviews_with_comment_cache_key
    "channel#{id}/reviews_with_comment"
  end

  # TODO: Review this piece of code, refactor and get rid of useless sht
  # see user#reviews
  def reviews_with_comment
    @reviews_with_comment ||= Rails.cache.fetch(reviews_with_comment_cache_key) { fetch_reviews_with_comment }
  end

  # # TODO: Review this piece of code, refactor and get rid of useless sht
  def reviews_with_rates(dimension = 'quality_of_content')
    Review.unscoped.select('reviews.*, (SUM(rates.stars)/COUNT(rates.*)) AS stars_quantity')
          .joins('JOIN rates ON rates.rateable_id = reviews.commentable_id AND rates.rateable_type = reviews.commentable_type AND rates.rater_id = reviews.user_id')
          .where("rates.dimension = :dimension AND (reviews.overall_experience_comment IS NOT NULL OR reviews.overall_experience_comment != '')", dimension: dimension)
          .where("(reviews.commentable_type = 'Session' AND reviews.commentable_id IN (SELECT sessions.id FROM sessions WHERE sessions.channel_id = :channel_id)) OR (reviews.commentable_type = 'Recording' AND reviews.commentable_id IN (SELECT recordings.id FROM recordings WHERE recordings.channel_id = :channel_id))", channel_id: id)
          .order('reviews.created_at DESC').group('reviews.id')
  end

  # TODO: Review this piece of code, refactor and get rid of useless sht
  def reviews_count(dimension = 'quality_of_content')
    Review.unscoped.distinct
          .joins('JOIN rates ON rates.rateable_id = reviews.commentable_id AND rates.rateable_type = reviews.commentable_type AND rates.rater_id = reviews.user_id')
          .where("rates.dimension = :dimension AND (reviews.overall_experience_comment IS NOT NULL OR reviews.overall_experience_comment != '')", dimension: dimension)
          .where("(reviews.commentable_type = 'Session' AND reviews.commentable_id IN (SELECT sessions.id FROM sessions WHERE sessions.channel_id = :channel_id)) OR (reviews.commentable_type = 'Recording' AND reviews.commentable_id IN (SELECT recordings.id FROM recordings WHERE recordings.channel_id = :channel_id))", channel_id: id)
          .count
  end

  def main_image
    @main_image ||= (cover || images.most_relevant.first || build_cover)
  end

  # original size
  def image_url
    @image_url ||= main_image.image_url
  end

  alias_method :poster_url, :image_url

  def logo_url
    @logo_url ||= logo ? logo.small_url : image_url
  end

  # cropped original size
  def image_gallery_url
    @image_gallery_url ||= main_image.image_gallery_url
  end

  alias_method :pinterest_share_preview_image_url, :image_gallery_url
  alias_method :share_image_url, :image_gallery_url

  # TODO: is this actual size?
  # [410, 230]
  def image_slider_url
    @image_slider_url ||= main_image.image_slider_url
  end

  # TODO: is this actual size?
  # [280, 280]
  def image_preview_url
    @image_preview_url ||= main_image.image_preview_url
  end

  # [700, 300]
  def image_mobile_preview_url
    @image_mobile_preview_url ||= main_image.image_mobile_preview_url
  end

  def image_tile_url
    @image_tile_url ||= main_image.image_tile_url
  end

  def changed_notifiable_attrs
    changes.dup.keep_if { |key| NOTIFY_ABOUT_UPDATES_IN_FIELDS.include?(key) }
  end

  def materials
    return [] if new_record?

    max_global_updated_at = ActiveRecord::Base.connection.execute('SELECT MAX(updated_at) FROM (SELECT updated_at FROM channel_images UNION SELECT updated_at FROM channel_links) AS foo').values.flatten.first
    _cache_key = "materials/#{id}/#{max_global_updated_at}"

    Rails.cache.fetch(_cache_key) do
      materials = (images + channel_links).sort_by(&:place_number)
      materials.insert(0, cover) if cover
      materials.map(&:channel_material)
    end
  end

  def slider_materials
    return [] if new_record?

    max_global_updated_at = ActiveRecord::Base.connection.execute('SELECT MAX(updated_at) FROM (SELECT updated_at FROM channel_images UNION SELECT updated_at FROM channel_links) AS foo').values.flatten.first
    _cache_key = "materials/#{id}/#{max_global_updated_at}"

    Rails.cache.fetch(_cache_key) do
      materials = (images + channel_links).sort_by(&:place_number)
      materials.insert(0, cover) if cover
      materials.map(&:slider_material)
    end
  end

  def past_sessions_count
    Rails.cache.fetch("#{__method__}/#{cache_key}") do
      sessions
        .not_fake
        .not_cancelled
        .not_archived
        .is_public
        .published
        .finished
        .count
    end
  end

  def archived?
    !!archived_at
  end

  def multisearch_reindex
    if Rails.env.test?
      begin
        update_pg_search_document
      rescue Errno::ECONNREFUSED => e
        Rails.logger.warn e.message
      end
    else
      IndexChannel.perform_async(id)
    end
  end

  def user_reindex
    organizer.multisearch_reindex
  end

  def normalize_friendly_id(_string)
    if organization.present?
      "#{organization.slug}/#{title.to_slug.normalize!(transliterations: %i[russian ukrainian latin spanish
                                                                            german]).to_slug.to_ascii}"
    else
      "#{presenter.user.slug}/#{title.to_slug.normalize!(transliterations: %i[russian ukrainian latin spanish
                                                                              german]).to_slug.to_ascii}"
    end
  end

  def available_presenter_ids
    p = []
    p << organizer.presenter if organizer.presenter
    p += presenters.reload.to_a
    if organization
      p += organization.employees.joins(:presenter).map(&:presenter)
    end
    p.collect(&:id).uniq
  end

  def description_text
    @description_text ||= Nokogiri::HTML.parse(description).inner_text
  end

  alias_method :share_description, :description_text

  def description_text_length
    description_text.length
  end

  def live_public_sessions
    sessions
      .for_all_ages
      .is_public
      .not_archived
      .not_cancelled
      .not_finished
      .published
      .order(start_at: :asc)
  end

  def recreate_urls
    update_short_urls
    ChannelJobs::SlugUpdated.perform_async(id)
  end

  def archive_subscription
    subscription&.update(enabled: false)
    Stripe::Product.update(stripe_id, active: false) if stripe_id.present?
  rescue StandardError => e
    Rails.logger.error e.message
  end

  def create_stripe_product!
    return if stripe_id.present?

    begin
      product = Stripe::Product.create(
        type: 'service',
        name: title
      )
      self.stripe_id = product.id
      save(validate: false)
    rescue StandardError => e
      Rails.logger.error e.message
      return
    end
  end

  def is_fake?
    fake? || organizer&.fake? || organization&.fake?
  end

  # We need this to get list of channel comments for reviews section on channel page
  def reviews
    Review.unscoped
          .joins(%(LEFT JOIN sessions ON sessions.id = reviews.commentable_id AND reviews.commentable_type = 'Session'))
          .joins(%(LEFT JOIN recordings ON recordings.id = reviews.commentable_id AND reviews.commentable_type = 'Recording'))
          .where(%{(reviews.commentable_type = 'Session' AND sessions.channel_id = :channel_id) OR (reviews.commentable_type = 'Recording' AND recordings.channel_id = :channel_id)}, channel_id: id)
  end

  def comments
    Comment.unscoped
           .joins(%(LEFT JOIN sessions ON sessions.id = comments.commentable_id AND comments.commentable_type = 'Session'))
           .joins(%(LEFT JOIN recordings ON recordings.id = comments.commentable_id AND comments.commentable_type = 'Recording'))
           .where(%{(comments.commentable_type = 'Session' AND sessions.channel_id = :channel_id) OR (comments.commentable_type = 'Recording' AND recordings.channel_id = :channel_id)}, channel_id: id)
  end

  def live_session_exists?
    sessions.live_now.count.positive?
  end

  private

  def not_archived_uniq_title
    errors.add(:title, 'this title is already taken') if Channel.not_archived.exists?(title: title)
  end

  # TODO: Review this piece of code, refactor and get rid of useless sht
  def fetch_reviews_with_comment
    reviews_with_rates.where.not(reviews: { overall_experience_comment: nil }).where(rates: { dimension: ::Rate::RateKeys::QUALITY_OF_CONTENT }).limit(50).offset(0).map do |comment|
      {
        rate_created_at: comment.created_at,
        comment: comment.overall_experience_comment,
        rateable: comment.commentable,
        stars_quantity: comment.stars_quantity,
        rater: comment.user
      }
    rescue StandardError
      next
    end
  end

  def should_generate_new_friendly_id?
    # NOTE: - do no include title_changed? here because we would need to update all nested sessions as well
    # (if you want to do it, you need to explore friendly_id's source)
    new_record? || slug.blank? || organization_id_changed? || title_changed? || slug.count('/').zero?
  end

  # NOTE: do not delete this method
  # it is needed for backward compatibility with friendly_id so that you don't need to patch it
  # #normalize_friendly_id is where magic happens
  def friendly_id_slug_candidate
    'whatever'
  end

  def just_got_approved?
    return unless saved_change_to_status?

    approved? && !listed? && list_automatically_after_approved_by_admin
  end

  def got_approved?
    return unless saved_change_to_status?

    approved?
  end

  def touch_sessions
    sessions.update_all(updated_at: Time.now.utc)
  end

  # TODO: use I18n
  def maximum_channel_images_compliance
    return if errors.include?(:images)

    if images.reject(&:marked_for_destruction?).size > SystemParameter.channel_images_max_count.to_i
      errors.add(:gallery, "must have at most #{SystemParameter.channel_images_max_count.to_i} images")
    end
  end

  # TODO: use I18n
  def max_channel_links
    if channel_links.reject(&:marked_for_destruction?).size > SystemParameter.channel_links_max_count.to_i
      errors.add(:channel_links, "amount must be at most #{SystemParameter.channel_links_max_count.to_i}")
    end
  end

  def clear_fields
    update_attribute(:rejection_reason, nil) if rejection_reason
  end

  def check_whether_was_rejected
    unless status == Statuses::APPROVED
      self.listed_at = nil
    end
  end

  def archived_skip_coming_soon
    if archived? && display_in_coming_soon_section
      errors.add(:display_in_coming_soon_section, "archived channel can't be displayed in coming soon section")
    end
  end

  def sanitize_description
    self.description = Sanitize.clean(description.to_s.html_safe, elements: %w[a b i br s u ul ol li p strong em],
                                                                  attributes: { a: %w[href target title] }.with_indifferent_access)
  end

  def ensure_organizer
    # if user has a company, then assign channel to it
    if presenter_id && presenter.user.organization
      self.organization = presenter.user.organization
      self.presenter_id = nil
    end
  end

  def notify_admins_about_changes
    csr_recipient_emails.each do |email|
      ChannelMailer.channel_updated(changed_notifiable_attrs, self, email).deliver_later
    end
  end

  def notify_organizer
    if rejected?
      ChannelMailer.channel_rejected(id).deliver_later
    elsif approved?
      ChannelMailer.channel_approved(id).deliver_later
    end
  end

  def description_text_length_validation
    length = description_text_length
    if length > LONG_TEXTAREA_MAX_LENGTH
      errors.add(:description, :too_long, count: LONG_TEXTAREA_MAX_LENGTH)
    end
  end

  def check_is_default
    organization.channels.where.not(id: id).update_all(is_default: false) if is_default?
  end

  def list_immediately
    update_attribute(:listed_at, Time.now)
  end

  def send_invites
    channel_invited_presenterships.each(&:send_invite!)
  end

  # Task 2657
  def ensure_belongs_to_one_entity
    if presenter_id
      if presenter.user.organization
        self.organization_id = presenter.user.organization.id
        self.presenter_id = nil
      else
        self.organization_id = nil
      end
    elsif organization_id
      self.presenter_id = nil
    end
  end

  def clear_user_listed_channels_cache
    presenters.each do |object|
      Rails.cache.delete("has_listed_channels?/#{object.user_id}/#{Channel.count}")
      object.user.schedule_update_pg_search_document
    end
    if presenter
      Rails.cache.delete("has_listed_channels?/#{presenter.user_id}/#{Channel.count}")
      presenter.user.schedule_update_pg_search_document
    end
    if organization&.user
      Rails.cache.delete("has_listed_channels?/#{organization.user.id}/#{Channel.count}")
      organization.user.schedule_update_pg_search_document
    end
  end

  def notify_im_conversation_disabled
    return if im_conversation.blank?

    ::Im::ConversationsChannel.broadcast_to im_conversation, event: 'channel_conversation_disabled', data: {}
  end
end
