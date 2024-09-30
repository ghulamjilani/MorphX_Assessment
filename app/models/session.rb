# frozen_string_literal: true
require 'babosa'

class Session < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions
  include ModelConcerns::HasShortUrl
  include ModelConcerns::ActsAsAbstractSession
  include ModelConcerns::OverlappedSessions
  include ModelConcerns::Session::StartAtCertainTime
  include ModelConcerns::Session::Recurring
  include ModelConcerns::Session::Free
  include ModelConcerns::Session::Private
  include ModelConcerns::Session::HasDonateOptions
  include ModelConcerns::Session::HasImmersiveDeliveryMethods
  include ModelConcerns::Session::HasNonImmersiveDeliveryMethods
  include ModelConcerns::Session::ZoomService
  include ModelConcerns::Session::WebrtcserviceService
  # include Concerns::Session::HasTwitterFeed
  include ModelConcerns::Session::HasInvitedUsers
  include ModelConcerns::Shared::ActsAsVideoAccount
  include ModelConcerns::Shared::RatyRate
  # include Concerns::CanWrapExternalUrls
  include ModelConcerns::Session::PgSearchable
  include ModelConcerns::Trackable
  include ModelConcerns::Shared::Viewable
  include ModelConcerns::Shared::HasPromoWeight
  include ModelConcerns::Im::HasConversation
  include ModelConcerns::Session::HasImConversation
  include ModelConcerns::Shared::HasLists
  include ModelConcerns::Shared::Blockable
  include ModelConcerns::Shared::ActsAsWishlistItem

  acts_as_votable # for likes
  paginates_per 12 # 3 rows by 4 columns with sessions

  extend FriendlyId
  friendly_id :friendly_id_slug_candidate, use: %i[slugged history]
  def normalize_friendly_id(_string)
    "#{channel.slug}/#{start_at.to_formatted_s(:short).parameterize}-#{title.to_slug.normalize!(transliterations: %i[
                                                                                                  russian ukrainian latin spanish german
                                                                                                ]).to_slug.to_ascii}"
  end

  mount_uploader :cover, SessionCoverUploader
  alias_attribute :carrierwave_id, :id

  attr_writer :immersive, :record, :livestream
  attr_accessor :update_by_organizer, :skip_cover_validation

  delegate :pinterest_share_preview_image_url, to: :channel
  delegate :organization, to: :channel, allow_nil: false
  delegate :interactive_guests, to: :organization
  delegate :show_comments, to: :channel
  delegate :show_reviews, to: :channel
  delegate :organization_id, to: :channel
  delegate :id, to: :room, prefix: true, allow_nil: true

  SHARE_IMAGE_WIDTH = 280
  SHARE_IMAGE_HEIGHT = 280
  RATING_MAX_START = 5
  PRE_TIME = [0, 5, 10, 15, 20, 25, 30, 45, 60].freeze
  MAX_PRE_TIME = PRE_TIME.max.freeze
  CHECK_NO_RESERVATION_TIME_PERCENT = 50
  PUBLIC_CHANNEL   = 'public-sessions'
  AGE_RESTRICTIONS = { none: 0, adult: 1, major: 2 }.freeze

  module ImmersiveTypes
    GROUP      = 'group'
    ONE_ON_ONE = 'one_on_one'
  end

  module Statuses
    UNPUBLISHED                     = 'unpublished'
    PUBLISHED                       = 'published'
    REQUESTED_FREE_SESSION_APPROVED = 'requested_free_session_approved'
    REQUESTED_FREE_SESSION_PENDING  = 'requested_free_session_pending'
    REQUESTED_FREE_SESSION_REJECTED = 'requested_free_session_rejected'

    ALL = [UNPUBLISHED, PUBLISHED, REQUESTED_FREE_SESSION_APPROVED, REQUESTED_FREE_SESSION_PENDING,
           REQUESTED_FREE_SESSION_REJECTED].freeze
  end

  module RateKeys
    # NOTE: be careful about renaming this key value or you may loose existing rates/calculation results
    QUALITY_OF_CONTENT    = 'quality_of_content'
    PRESENTER_PERFORMANCE = 'presenter_performance'

    VIDEO_QUALITY = 'video_quality'
    SOUND_QUALITY = 'sound_quality'

    IMMERSS_EXPERIENCE = 'immerss_experience'
    ALL = [
      QUALITY_OF_CONTENT,
      PRESENTER_PERFORMANCE,
      VIDEO_QUALITY,
      SOUND_QUALITY,
      IMMERSS_EXPERIENCE
    ].freeze

    PRESENTER = [
      IMMERSS_EXPERIENCE,
      VIDEO_QUALITY,
      SOUND_QUALITY
    ].freeze

    USER = [
      QUALITY_OF_CONTENT,
      VIDEO_QUALITY,
      SOUND_QUALITY
    ].freeze

    MANDATORY = [
      QUALITY_OF_CONTENT
    ].freeze
  end

  module ServiceStatuses
    OFF       = 'off'
    UP        = 'up'
    DOWN      = 'down'
    STARTING  = 'starting'

    ALL = [OFF, UP, DOWN, STARTING].freeze
  end

  ServiceStatuses::ALL.each do |const|
    define_method("service_status_#{const}?") { service_status == const }
    define_method("service_status_#{const}!") { update_attribute(:service_status, const) }
  end

  ratyrate_rateable(*RateKeys::ALL)

  belongs_to :channel, inverse_of: :sessions, touch: true
  belongs_to :presenter, touch: true
  belongs_to :mind_body_db_class_schedule, class_name: 'MindBodyDb::ClassSchedule', inverse_of: :sessions,
                                           foreign_key: :mind_body_db_class_schedule_id
  belongs_to :ffmpegservice_account

  has_one :session_waiting_list, dependent: :destroy, required: true
  has_one :user, through: :presenter
  has_one :zoom_meeting, dependent: :destroy
  has_one :booking, class_name: 'Booking::Booking'

  has_many :interactive_access_tokens
  has_many :individual_interactive_tokens, -> { where(individual: true) }, class_name: 'InteractiveAccessToken'
  has_one :shared_interactive_token, -> { where(individual: false) }, class_name: 'InteractiveAccessToken'

  has_many :payment_transactions, as: :purchased_item, dependent: :destroy
  has_many :system_credit_entries, as: :commercial_document, dependent: :destroy
  has_many :log_transactions, as: :abstract_session, dependent: :destroy
  has_many :organizer_abstract_session_pay_promises, as: :abstract_session, dependent: :destroy, autosave: true
  has_many :session_invited_immersive_participantships,  dependent: :destroy, autosave: true
  has_many :session_invited_immersive_co_presenterships, dependent: :destroy, autosave: true
  has_many :session_invited_livestream_participantships, dependent: :destroy, autosave: true
  has_many :records, through: :room, source: :videos
  has_many :livestreamers, dependent: :destroy, autosave: true
  has_many :livestream_participants, through: :livestreamers, source: :participant
  has_many :recorded_members, dependent: :destroy, as: :abstract_session, autosave: true
  has_many :recorded_participants, through: :recorded_members, source: :participant
  has_many :session_participations, dependent: :destroy, autosave: true
  has_many :immersive_participants, through: :session_participations, source: :participant
  has_many :session_co_presenterships, dependent: :destroy, autosave: true
  has_many :co_presenters, through: :session_co_presenterships, source: :presenter
  has_many :dropbox_materials, as: :abstract_session, dependent: :destroy
  has_many :session_sources, dependent: :destroy
  has_many :room_members, through: :room
  has_many :reviews, as: :commentable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :polls, class_name: 'Poll::Poll', as: :model, dependent: :destroy

  accepts_nested_attributes_for :session_sources, allow_destroy: true
  accepts_nested_attributes_for :dropbox_materials, allow_destroy: true
  accepts_nested_attributes_for :session_invited_immersive_participantships
  accepts_nested_attributes_for :session_invited_livestream_participantships

  scope :featured, -> { where(featured: true) }
  scope :vod, -> { where.not(recorded_purchase_price: nil) }
  scope :is_public, -> { where(private: false) }
  scope :ongoing_or_upcoming, lambda {
                                where("(:time_now > start_at AND :time_now < (start_at + (INTERVAL '1 minute' * duration))) OR :time_now < start_at", { time_now: Time.now.utc })
                              }
  scope :ongoing, lambda {
                    where("(:time_now > start_at AND :time_now < (start_at + (INTERVAL '1 minute' * duration)))", { time_now: Time.now.utc })
                  }
  scope :not_stopped, -> { where(stopped_at: nil) }
  scope :stopped, -> { where.not(stopped_at: nil) }
  scope :fake, -> { where('sessions.fake IS TRUE') }
  scope :not_fake, -> { where('sessions.fake IS FALSE') }
  scope :for_home_page, -> { where('sessions.show_on_home IS TRUE') }
  scope :published, -> { where(status: :published) }
  scope :not_archived, -> { joins(:channel).where(channels: { archived_at: nil }) }
  scope :for_all_ages, -> { where(age_restrictions: 0, adult: false) }
  scope :for_adult_ages, ->  { where.not(age_restrictions: 2).where(adult: false) }
  scope :for_major_ages, ->  { where(age_restrictions: AGE_RESTRICTIONS.values) }
  scope :for_user_with_age, lambda { |user|
    if user
      ability = AbilityLib::Legacy::Ability.new(user)
      if ability.can?(:view_major_content, user)
        for_major_ages
      elsif ability.can?(:view_adult_content, user)
        for_adult_ages
      else
        for_all_ages
      end
    else
      for_all_ages
    end
  }
  scope :with_participants_count, lambda {
    select(%{ "sessions".*, COUNT("participants"."id") as immersive_participants_count, COUNT("livestream_participants"."id") as livestream_participants_count })
      .joins(%( LEFT OUTER JOIN "session_participations" ON "sessions"."id" = "session_participations"."session_id" ))
      .joins(%( LEFT OUTER JOIN "participants" ON "session_participations"."participant_id" = "participants"."id" ))
      .joins(%( LEFT OUTER JOIN "livestreamers" ON "sessions"."id" = "livestreamers"."session_id" ))
      .joins(%( LEFT OUTER JOIN "participants" AS livestream_participants ON "livestreamers"."participant_id" = "livestream_participants"."id" ))
      .group(%( "sessions"."id" ))
  }

  scope :live_now, lambda {
    where('sessions.stopped_at IS NULL AND sessions.start_at IS NOT NULL AND sessions.start_at < :time_now', { time_now: Time.now.utc })
      .where("(sessions.start_at + (INTERVAL '1 minute' * sessions.duration)) > :time_now", { time_now: Time.now.utc })
  }

  def self.visible_for(user = nil)
    if user
      select(%("sessions".*, COUNT("participants"."id") as immersive_participants_count, COUNT("livestream_participants"."id") as livestream_participants_count))
        .joins(:channel)
        .joins(%(LEFT OUTER JOIN "presenters" AS owners ON "channels"."presenter_id" = "owners"."id"))
        .joins(%(LEFT OUTER JOIN "organizations" ON "organizations"."id" = "channels"."organization_id"))
        .joins(%(LEFT OUTER JOIN "channel_invited_presenterships" ON "channel_invited_presenterships"."channel_id" = "channels"."id" AND "channel_invited_presenterships"."status" = 'accepted'))
        .joins(%(LEFT OUTER JOIN "presenters" AS channel_members ON "channel_invited_presenterships"."presenter_id" = "channel_members"."id"))
        .joins(%(LEFT OUTER JOIN "livestreamers" ON "sessions"."id" = "livestreamers"."session_id"))
        .joins(%(LEFT OUTER JOIN "participants" AS livestream_participants ON "livestreamers"."participant_id" = "livestream_participants"."id"))
        .joins(%(LEFT OUTER JOIN "session_participations" ON "sessions"."id" = "session_participations"."session_id"))
        .joins(%(LEFT OUTER JOIN "participants" ON "session_participations"."participant_id" = "participants"."id"))
        .joins(%(LEFT OUTER JOIN "session_co_presenterships" ON "sessions"."id" = "session_co_presenterships"."session_id"))
        .joins(%(LEFT OUTER JOIN "presenters" AS co_presenters ON "session_co_presenterships"."presenter_id" = "co_presenters"."id"))
        .where(%("sessions"."private" IS FALSE OR ("sessions"."private" IS TRUE AND ("participants"."user_id" = :id OR "co_presenters"."user_id" = :id OR "livestream_participants"."user_id" = :id OR "owners"."user_id" = :id OR "channel_members"."user_id" = :id OR "organizations"."user_id" = :id OR "sessions"."presenter_id" = :presenter_id))), id: user.id, presenter_id: (user.presenter ? user.presenter.id : -1))
        .group(%("sessions"."id"))
    else
      joins(:channel).is_public.with_participants_count.where.not(channels: { listed_at: nil }).where(
        channels: { archived_at: nil, fake: false }, users: { fake: false }
      )
    end.joins(presenter: :user).where(channels: { status: :approved })
  end

  before_validation do
    self.title = title.to_s.strip
    self.pre_time = 5 if autostart && pre_time.to_i.zero?
  end

  before_validation :sanitize_custom_description_field_value
  before_validation :normalize_if_one_on_one
  before_validation :set_default_status
  before_validation :build_waiting_list, on: :create
  before_validation :autoassign_main_wa, if: proc { |s|
                                               s.ffmpegservice_account_id.blank? && s.presenter_id.present? && s.channel.available_presenter_ids.include?(s.presenter_id) && [Room::ServiceTypes::MOBILE].include?(s.service_type)
                                             }
  after_create :schedule_accounting_closing
  after_create :update_short_urls
  after_create :create_zoom_meeting, if: proc { |s| s.service_type == 'zoom' }
  after_update :notify_waiting_list, if: :saved_change_to_max_number_of_immersive_participants?
  after_update :notify_unnotified_invited_participants, if: :just_got_published?
  after_update :invalidate_nearest_abstract_session_cache_for_everyone_involved, if: :just_got_published?
  after_update :published_notify_followers, if: :just_got_published?
  after_update :notify_assigned_presenter, if: :just_got_published?
  after_update :send_notifications,
               if: :first_session_in_presentattion_just_got_published?
  after_update :notify_presenters, if: :saved_change_to_presenter_id?
  after_update :trigger_live_refresh, if: proc { |obj| obj.saved_change_to_start_at? }
  after_update :schedule_accounting_closing, if: proc { |obj|
                                                   obj.saved_change_to_start_at? || obj.saved_change_to_duration?
                                                 }
  after_update :cable_notification_service_status_changed, if: :saved_change_to_service_status?
  after_update :cable_notification_allow_chat_changed, if: :saved_change_to_allow_chat?

  before_destroy :remove_videos_from_multisearch, prepend: true

  after_save :assign_im_conversation, if: proc { |session| session.allow_chat? && (session.instance_variable_get(:@_new_record_before_last_commit) || session.saved_change_to_allow_chat?) }

  after_commit :recreate_urls, on: :update, if: proc { |obj| obj.slug.present? && obj.saved_change_to_slug? }

  before_destroy do
    invalidate_nearest_abstract_session_cache_for_everyone_involved
  end

  after_commit on: :update do
    if saved_change_to_status? && status == Session::Statuses::REQUESTED_FREE_SESSION_PENDING
      SessionMailer.pending_requested_free_session_appeared(id).deliver_later
    end
  end

  after_commit on: :create do
    if status == Session::Statuses::REQUESTED_FREE_SESSION_PENDING
      SessionMailer.pending_requested_free_session_appeared(id).deliver_later
    end
  end

  # @return [Integer]
  def valid_durations
    return (15..180).step(5).to_a if (Rails.env.test? || Rails.env.development?) && presenter.blank? # because some factories are not really good at assigning hierarchies

    (15..duration_available_max).step(5).to_a
  end

  def duration_available_max
    duration_max_value = [duration_was.to_i, organizer.can_create_sessions_with_max_duration].max # duration could be already overriden by admin
    return duration_max_value if organization.split_revenue?

    return 45 if organization.service_subscription&.service_status == 'trial'

    (organization.service_subscription_feature_value(:max_session_duration) || duration_max_value).to_i
  end

  def self.valid_levels
    ['All Levels', 'Beginner', 'Intermediate', 'Advanced']
  end

  validate :recurring_settings_limit
  validate :at_least_one_delivery_method
  validate :checked_delivery_methods_are_present
  validates :status, presence: true
  validate :check_if_duration_is_available
  validates :immersive_type, inclusion: { in: [ImmersiveTypes::GROUP, ImmersiveTypes::ONE_ON_ONE] },
                             if: :immersive_delivery_method?
  validates :recording_layout, inclusion: { in: ::Webrtcservice::Video::Composition::Layouts::ALL }
  validates :channel, presence: true
  validates :title, length: { within: 2..72 }
  validate  :custom_description_field_value_text_length
  validates :age_restrictions, inclusion: { in: AGE_RESTRICTIONS.values, message: I18n.t('errors.messages.blank') }
  validates :pre_time, inclusion: { in: Session::PRE_TIME }
  validates :channel_id, presence: true
  validates :presenter_id, presence: true, inclusion: { in: ->(s) { s.channel.available_presenter_ids } }
  validates :start_at, presence: true
  validates :recorded_purchase_price, allow_nil: true, numericality: { greater_than: -1, less_than: 1_000_000 }
  validates :device_type,
            inclusion: { in: %w[desktop_basic mobile desktop_advanced professional studio_equipment ipcam zoom webrtcservice
                                webrtc] }
  validate :cover_dimensions_and_size_validity, if: ->(s) { s.cover_changed? && !s.skip_cover_validation }
  validates :status, inclusion: { in: Statuses::ALL }
  validates :level, inclusion: { in: valid_levels }, if: :display_level?
  validates :ffmpegservice_account_id, presence: true, if: ->(s) { s.ffmpegservice? }
  validate :check_concurrent_immersive_participants, if: ->(s) { s.webrtcservice? }
  validate :check_business_subscription, if: :new_record?
  validate :switch_service_type_validation, if: ->(s) { s.service_type_changed? || s.ffmpegservice_account_id_changed? }

  def ffmpegservice?
    [Room::ServiceTypes::WEBRTC, Room::ServiceTypes::IPCAM, Room::ServiceTypes::RTMP,
     Room::ServiceTypes::MOBILE].include?(service_type)
  end

  def zoom?
    service_type.eql?(Room::ServiceTypes::ZOOM)
  end

  def raters_count
    @raters_count ||= Rate.select(:rater_id).where(rateable_id: id, rateable_type: 'Session',
                                                   dimension: [Session::RateKeys::QUALITY_OF_CONTENT, Session::RateKeys::PRESENTER_PERFORMANCE]).distinct.count
  end

  def participants_count
    Rails.cache.fetch("#{__method__}/#{cache_key}") do
      session_participations.count + livestreamers.count
    end
  end

  def default_title(user = nil)
    [(user || channel.organizer).public_display_name, 'Live Session'].join(' ')[0..69]
  end

  def stop!(reason = nil)
    self.stop_reason = reason if reason
    self.stopped_at = Time.now
    save(validate: false)
    polls.enabled.find_each(&:stop!)
  end

  def in_progress?
    running? && room.active? && service_status_up?
  end

  def self.you_may_also_like(current_user)
    @you_may_also_like ||= {}
    @you_may_also_like[current_user.try(:id) || :unsigned_in] ||= Session
                                                                  .joins('LEFT OUTER JOIN channels ON channels.id = sessions.channel_id')
                                                                  .is_public
                                                                  .not_cancelled
                                                                  .not_fake
                                                                  .for_user_with_age(current_user)
                                                                  .where('sessions.immersive_purchase_price IS NOT NULL OR sessions.livestream_purchase_price IS NOT NULL')
                                                                  .where('channels.listed_at IS NOT NULL AND channels.fake IS FALSE')
                                                                  .published
                                                                  .upcoming
                                                                  .preload(:channel)
                                                                  .order(Arel.sql('random()'))
                                                                  .limit(4)
  end

  def as_json(options)
    date = start_at || Time.zone.now.beginning_of_hour
    hash = {
      start_at_date: date.strftime('%m/%d/%Y'),
      start_at_time: date.strftime('%H:%M %p'),
      start_at_year: date.year,
      start_at_month: date.month,
      start_at_day: date.day,
      start_at_hours: date.hour,
      start_at_minutes: date.min,
      livestream: livestream_delivery_method?,
      immersive: immersive_delivery_method?,
      record: recorded_delivery_method?
    }
    super(options).merge(hash)
  end

  def self.underscorjs_additional_methods
    %i[
      can_change_immersive
      can_change_immersive_access_cost
      can_change_immersive_free_slots
      can_change_immersive_type
      can_change_livestream
      immersive_access_cost
      livestream_access_cost
      recorded_access_cost
      can_change_livestream_access_cost
      can_change_livestream_free_slots
      can_change_max_number_of_immersive_participants
      can_change_min_number_of_immersive_and_livestream_participants
      can_change_private
      can_change_recorded_access_cost
      can_change_vod
      can_change_start_at
      has_participants
      immersive_participants_count
      max_number_of_immersive_participants_with_sources
      private
      belongs_to_listed_channel
      requested_free_session_reason
      started
      status
      list_ids
      stream_m3u8_url
      medium_cover_url
    ]
  end

  def self.archived_session_ids
    select('DISTINCT sessions.id').joins(:channel).where('channels.archived_at IS NOT NULL').map(&:id)
  end

  def self.for_home_page_live_guide(date_param:, organizers_param:, used_timezone:, current_user:)
    since_time = Chronic.parse(date_param).in_time_zone(used_timezone).beginning_of_day
    until_time = since_time.end_of_day

    Session
      .organizers_all_or_by_ids(organizers_param)
      .not_cancelled
      .is_public
      .published
      .where(fake: false, start_at: (since_time..until_time))
      .where('immersive_purchase_price IS NOT NULL OR livestream_purchase_price IS NOT NULL')
      .for_user_with_age(current_user)
      .includes(channel: :category)
  end

  def self.for_channel_page_live_guide(channel_id:, date_param:, used_timezone:, current_user:)
    since_time = Chronic.parse(date_param).in_time_zone(used_timezone).beginning_of_day
    until_time = since_time.end_of_day

    Session
      .not_cancelled
      .is_public
      .published
      .where(channel_id:  channel_id)
      .where(fake: false, start_at: (since_time..until_time))
      .where('immersive_purchase_price IS NOT NULL OR livestream_purchase_price IS NOT NULL')
      .for_user_with_age(current_user)
      .includes(channel: :category)
  end

  def self.for_organization_page_live_guide(organization_id:, date_param:, organizers_param:, used_timezone:, current_user:)
    since_time = Chronic.parse(date_param).in_time_zone(used_timezone).beginning_of_day
    until_time = since_time.end_of_day

    Session
      .organizers_all_or_by_ids(organizers_param)
      .not_cancelled
      .is_public
      .published
      .where("channel_id IN (SELECT id FROM channels WHERE organization_id = #{organization_id})")
      .where(start_at: (since_time..until_time))
      .where('immersive_purchase_price IS NOT NULL OR livestream_purchase_price IS NOT NULL')
      .for_user_with_age(current_user)
      .includes(channel: :category)
  end

  def has_twitter_feed?
    twitter_feed_title.present? && twitter_feed_widget_id.present? && twitter_feed_href.present?
  end

  # NOTE: options are "with dropbox materials" and/or "with invites"
  #      if session doesn't have either it is cloned by skipping "preview_clone" modal
  def cloneable_with_options?
    Rails.cache.fetch("#{__method__}/#{cache_key}") do
      session_invited_immersive_participantships.present? \
        || session_invited_livestream_participantships.present? \
        || dropbox_materials.present?
    end
  end

  # this method is needed to update present "Join" buttons without page refresh
  # in case when start at time changes
  def trigger_live_refresh
    # NOTE: start_at for organizers has to be like: abstract_session.start_at.to_i
    #      for all other roles it has to be room.actual_start_at.to_i
    #      (because of pre-time)
    #      but we only care about regular users here. Presenters see those pages right after updates anyway

    RoomsChannel.broadcast 'update', { room_id: room.id, now: Time.now.to_i, start_at: room.actual_start_at.to_i }
  end

  def revenue_split
    organization.user.revenue_percent / 100.0
  end

  def creator_interactive_revenue
    if immersive_purchase_price.nil? || immersive_purchase_price.zero?
      0
    else
      participants_count = paid_immersive_session_participations.count
      return 0 if participants_count.zero?

      (((participants_count * immersive_purchase_price.to_f) - immersive_service_fee) * revenue_split).round(2)
    end
  end

  def creator_livestream_revenue
    if livestream_purchase_price.nil? || livestream_purchase_price.zero?
      0
    else
      participants_count = paid_livestreamers.count
      return 0 if participants_count.zero?

      (((participants_count * livestream_purchase_price.to_f) - livestream_service_fee) * revenue_split).round(2)
    end
  end

  def immerss_interactive_revenue
    if immersive_purchase_price.nil? || immersive_purchase_price.zero?
      0
    else
      participants_count = paid_immersive_session_participations.count
      return 0 if participants_count.zero?

      revenue_split_multiplier = (100 - revenue_split) / 100.0
      (((participants_count * immersive_purchase_price.to_f) - immersive_service_fee) * revenue_split_multiplier).round(2)
    end
  end

  def immerss_livestream_revenue
    if livestream_purchase_price.nil? || livestream_purchase_price.zero?
      0
    else
      participants_count = paid_livestreamers.count
      return 0 if participants_count.zero?

      revenue_split_multiplier = (100 - revenue_split) / 100.0
      (((participants_count * livestream_purchase_price.to_f) - livestream_service_fee) * revenue_split_multiplier).round(2)
    end
  end

  # NOTE: set it to 0 for now because we need to rewrite expression for new service
  # NOTE: if you ever need to update it, make sure it is also duplicated in coffeescript for client side validation
  def immersive_service_fee
    0.0
    # ((duration / 5 - 2) * 0.1 + 1.5).round(2)
  end

  # NOTE: if you ever need to update it, make sure it is also duplicated in coffeescript for client side validation
  def livestream_service_fee
    0.0
    # ((duration / 5 - 2) * 0.1 + 0.5).round(2)
  end

  # NOTE: if you ever need to update it, make sure it is also duplicated in coffeescript for client side validation
  def recorded_service_fee
    0.0
    # ((duration / 5 - 2) * 0.05).round(2)
  end

  # NOTE: if you ever need to update it, make sure it is also duplicated in coffeescript for client side validation
  def immersive_min_access_cost
    # (organizer && organizer.overriden_minimum_live_session_cost) ? organizer.overriden_minimum_live_session_cost : ((duration / 5 - 2) * 0.5 + 4.99).round(2)
    organizer&.overriden_minimum_live_session_cost ? organizer.overriden_minimum_live_session_cost : 4.99
  end

  # NOTE: if you ever need to update it, make sure it is also duplicated in coffeescript for client side validation
  def livestream_min_access_cost
    # (organizer && organizer.overriden_minimum_live_session_cost) ? organizer.overriden_minimum_live_session_cost : ((duration / 5 - 2) * 0.2 + 2.99).round(2)
    organizer&.overriden_minimum_live_session_cost ? organizer.overriden_minimum_live_session_cost : 2.99
  end

  # NOTE: if you ever need to update it, make sure it is also duplicated in coffeescript for client side validation
  def recorded_min_access_cost
    # ((duration / 5 - 2) * 0.05 + 0.99).round(2)
    0.99
  end

  def immersive_access_cost=(value)
    if value == ''
      self.immersive_purchase_price = nil
    elsif value.present?
      begin
        self.immersive_purchase_price = Float(value) + immersive_service_fee
      # fixes "Invalid value for Float("foo")
      rescue ArgumentError => e
        Rails.logger.debug e.message
        Rails.logger.debug e.backtrace
      end
    end
  end

  def livestream_access_cost=(value)
    if value == ''
      self.livestream_purchase_price = nil
    elsif value.present?
      begin
        self.livestream_purchase_price = Float(value) + livestream_service_fee
      # fixes "Invalid value for Float("foo")
      rescue ArgumentError => e
        Rails.logger.debug e.message
        Rails.logger.debug e.backtrace
      end
    end
  end

  def recorded_access_cost=(value)
    if value.blank?
      self.recorded_purchase_price = nil
    elsif value.to_f.to_s == value.to_s || value.to_i.to_s == value.to_s
      self.recorded_purchase_price = if value.to_f.zero?
                                       Float(0)
                                     else
                                       Float(value) + recorded_service_fee
                                     end
    end
  end

  # it includes service fee
  # price that participant has to pay to acquire it
  def immersive_access_cost
    return unless immersive_delivery_method?

    # return 0 if completely_free?
    return 0 if immersive_purchase_price.nil? || immersive_purchase_price.zero?

    # return 0 if status == Statuses::REQUESTED_FREE_SESSION_PENDING
    # return 0 if status == Statuses::REQUESTED_FREE_SESSION_APPROVED
    # return 0 if status == Statuses::REQUESTED_FREE_SESSION_REJECTED

    (immersive_purchase_price - immersive_service_fee).round(2)
  end

  def livestream_access_cost
    return unless livestream_delivery_method?

    # return 0 if completely_free?
    return 0 if livestream_purchase_price.nil? || livestream_purchase_price.zero?

    # return 0 if status == Statuses::REQUESTED_FREE_SESSION_PENDING
    # return 0 if status == Statuses::REQUESTED_FREE_SESSION_APPROVED
    # return 0 if status == Statuses::REQUESTED_FREE_SESSION_REJECTED

    (livestream_purchase_price - livestream_service_fee).round(2)
  end

  def recorded_access_cost
    return unless recorded_delivery_method?

    return 0 if recorded_purchase_price.nil? || recorded_purchase_price.zero?

    (recorded_purchase_price - recorded_service_fee).round(2)
  end

  def total_participants_count
    Rails.cache.fetch("#{__method__}/#{cache_key}") do
      session_participations.count + livestreamers.count
    end
  end

  # NOTE: this method is used only in #underscorjs_additional_methods
  # @return [Boolean]
  def has_participants
    Rails.cache.fetch("#{__method__}/#{cache_key}") do
      session_participations.present? || livestreamers.present?
    end
  end

  def has_participants?
    !!has_participants
  end

  def immersive_participants_count
    @immersive_participants_count ||= session_participations.count
  end

  def sources_count
    @session_sources ||= session_sources.count
  end

  def max_number_of_immersive_participants_with_sources
    case service_type
    when 'zoom'
      max_number_of_zoom_participants
    else
      max_number_of_webrtcservice_participants
    end - sources_count
  end

  def max_number_of_zoom_participants
    99
  end

  def ongoing?
    started? && !finished?
  end

  def can_change_immersive?
    return false if started?
    return false if requested_free_session_satisfied_at.present?
    return false if session_participations.present?

    true
  end

  def can_change_livestream?
    return false if started?
    return false if requested_free_session_satisfied_at.present?
    return false if livestreamers.present?

    true
  end

  def can_change_vod?
    recorded_members.blank?
  end

  def notify_presenters
    if status == Session::Statuses::PUBLISHED
      notify_assigned_presenter
      notify_previous_presenter
    end
  end

  def notify_assigned_presenter
    if is_not_owner?(presenter_id)
      SessionMailer.presenter_assigned_to_session(id, presenter_id).deliver_later
    end
  end

  def notify_previous_presenter
    if is_not_owner?(presenter_id_before_last_save)
      SessionMailer.presenter_unassigned_from_session(id, presenter_id_before_last_save).deliver_later
    end
  end

  def notify_waiting_list
    return if session_waiting_list.users.count.zero?

    if max_number_of_immersive_participants.to_i > max_number_of_immersive_participants_before_last_save.to_i
      CheckSessionWaitingList.perform_async(id)
    end
  end

  def paid_immersive_session_participations
    co_presenter_user_ids = session_co_presenterships.collect { |presenter| presenter.user.id }
    # FIXME: BRAINTREE
    paid_participant_ids  = payment_transactions
                            .success
                            .where(type: TransactionTypes::IMMERSIVE)
                            .where.not(user_id: co_presenter_user_ids) # fixes #1336
                            .collect { |bt| bt.user.try(:participant).try(:id) }.compact

    session_participations.where(participant_id: paid_participant_ids)
  end

  def paid_livestreamers
    paid_participant_ids = payment_transactions.not_archived.success.where(type: TransactionTypes::LIVESTREAM).collect do |bt|
      bt.user.participant_id
    end
    livestreamers.where(participant_id: paid_participant_ids)
  end

  def unpublished?
    status == Session::Statuses::UNPUBLISHED
  end

  def published?
    status == Session::Statuses::PUBLISHED
  end

  # overriding letsrate model
  # see https://github.com/wazery/ratyrate/blob/master/lib/ratyrate/model.rb#L105
  # and https://github.com/wazery/ratyrate/blob/master/lib/ratyrate/helpers.rb#L36
  def can_rate?(user, dimension = nil)
    return false unless user&.persisted?
    return false if rates(dimension).where(rater_id: user.id).count.positive?

    has_rate_ability = Rails.cache.fetch("can_rate/#{user.cache_key}/#{cache_key}") do
      ::AbilityLib::SessionAbility.new(user).can?(:rate, self)
    end
    return false unless has_rate_ability

    rate_keys = (organizer == user) ? ::Session::RateKeys::PRESENTER : ::Session::RateKeys::USER
    rate_keys.include?(dimension)
  end

  def object_label
    title
  end

  def display_level?
    !channel.performance_type?
  end

  def relative_path
    friendly_id ? "/#{friendly_id}" : raise("session #{id} does not have #friendly_id. title: #{title}")
  end

  def toggle_like_relative_path
    "#{relative_path}/toggle_like"
  end

  def preview_share_relative_path(params = {})
    "#{relative_path}/preview_share#{"?#{params.to_query}" if params.present?}"
  end

  def share_title
    I18n.t('models.session.share_title', organizer_share_title: organizer.share_title, channel_title: channel.title,
                                         title: (title.present? ? ": #{title}" : ''), always_present_title: always_present_title)
  end

  def share_description
    "#{short_url} \n" +
      "#{always_present_description}. \n" +
      "Date: #{start_at.in_time_zone(Time.zone).strftime('%d %b %I:%M %p %Z')}"
  end

  def share_image_url
    player_cover_url
  end

  def cropping?
    crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
  end

  def small_cover_url
    if cover.present?
      cover.small.url
    else
      channel.image_slider_url
    end
  end

  def medium_cover_url
    if cover.present?
      cover.medium.url
    else
      channel.image_mobile_preview_url
    end
  end
  alias_method :poster_url, :medium_cover_url

  def large_cover_url
    if cover.present?
      cover.large.url
    else
      channel.image_gallery_url
    end
  end

  def player_cover_url
    if cover.present?
      cover.player.url
    else
      channel.image_gallery_url
    end
  end

  def main_filename
    attributes['cover']
  end

  # utm_params are needed for tracking visits from email links
  # @see UTM dependency
  # refc_user for sharing
  # @see SharingHelper, SharedControllerHelper
  def absolute_path(utm_params = nil, refc_user = nil)
    request_protocol = ActionMailer::Base.default_url_options[:protocol] || 'http://'
    host             = ActionMailer::Base.default_url_options[:host] or raise 'cant get HOST'

    result = "#{request_protocol}#{host}#{relative_path}"

    unless result&.match?(URI::DEFAULT_PARSER.make_regexp)
      raise "check your protocol/host env properties - invalid URL format for session - #{result} ; #{request_protocol} ; #{host}"
    end

    params = []
    params << utm_params if utm_params
    params << "refc=#{refc_user.my_referral_code_text}" if refc_user.is_a?(User)
    result += "?#{params.join('&')}" unless params.empty?
    result
  end

  def likes_cache_key
    "likes/#{self.class.to_s.downcase}/#{id}"
  end

  def likes_count
    Rails.cache.fetch(likes_cache_key) do
      get_likes.count
    end
  end

  def remove_from_waiting_list(user)
    session_waiting_list.session_waiting_list_memberships.where(user_id: user.id).destroy_all
  end

  def immersive_delivery_method?
    # NOTE: - cost could be zero in free sessions
    !immersive_purchase_price.nil?
  end

  alias :interactive_delivery_method? :immersive_delivery_method?

  def line_slots_left
    if immersive_type == Session::ImmersiveTypes::ONE_ON_ONE
      result = 1 - immersive_participants.count
      raise "could not be negative(#{result}), session: ##{id}" if result.negative?

      result
    else
      return nil if max_number_of_immersive_participants.nil?

      max_number_of_immersive_participants - interactive_participants_count
    end
  end

  def interactive_participants_count
    [immersive_participants.count, room_members.audience.not_banned.count].max
  end

  def interactive_slots_available?
    return false unless immersive_delivery_method?

    (((immersive_type == Session::ImmersiveTypes::ONE_ON_ONE) ? 1 : max_number_of_immersive_participants.to_i) - interactive_participants_count).positive?
  end

  def available_delivery_methods
    available_methods = []
    available_methods << :livestream if livestream_delivery_method?
    available_methods << :immersive if immersive_delivery_method? && line_slots_left.positive?
    available_methods
  end

  # @return [User]
  def organizer
    @organizer ||= presenter&.user || organization&.user
  end

  def popover_data(time_format)
    result = {}

    max = if immersive_type == ImmersiveTypes::ONE_ON_ONE
            1
          else
            max_number_of_immersive_participants
          end
    occupied = immersive_participants.count
    presenter_name = organizer.public_display_name

    result.merge!({
                    is_immersive: immersive_delivery_method?,
                    is_livestream: livestream_delivery_method?,
                    seats_total: max,
                    seats_occupied: occupied,
                    presenter_name: presenter_name,
                    immersive_purchase_price: if immersive_delivery_method?
                                                ActiveSupport::NumberHelper.number_to_currency(
                                                  immersive_purchase_price.to_f, precision: 2
                                                )
                                              end,
                    livestream_purchase_price: if livestream_delivery_method?
                                                 ActiveSupport::NumberHelper.number_to_currency(
                                                   livestream_purchase_price.to_f, precision: 2
                                                 )
                                               end,
                    duration: duration,
                    title: channel.title,
                    time_format: time_format.eql?(User::TimeFormats::HOUR_24) ? User::TimeFormats::HOUR_24 : User::TimeFormats::HOUR_12
                  })

    result
  end

  # so that you don't need a custom migration across 3 envs
  def always_present_description
    description.presence || channel.description
  end

  # Notification always expect not-nil title, but subtitle could be nil.
  # that's why this workround exists
  def always_present_title
    title.presence || channel.title
  end

  def can_change_min_number_of_immersive_and_livestream_participants?
    return true unless persisted? # new, unsaved session
    return false if started? || cancelled?
    return false if published?

    types = [TransactionTypes::IMMERSIVE, TransactionTypes::LIVESTREAM]
    payment_transactions.success.not_archived.where(type: types).blank?
  end

  def can_change_immersive_type?
    return true unless persisted? # new, unsaved session
    return false if started? || cancelled?

    session_participations.blank? && livestreamers.blank?
  end

  def can_change_pre_time?
    return true unless persisted? # new, unsaved session

    !started?
  end

  def can_change_max_number_of_immersive_participants?
    return true unless persisted? # new, unsaved session

    !started? && !finished?
  end

  def can_change_private?
    return true unless persisted? # new, unsaved session
    return false if started?
    return false if status == Statuses::REQUESTED_FREE_SESSION_APPROVED || status == Statuses::REQUESTED_FREE_SESSION_PENDING

    # NOTE: can not change from public to private!
    # return false unless private?

    return false if has_participants?

    true
  end

  underscorjs_additional_methods.each do |method|
    if method.to_s.start_with?('can_', 'started')
      # for easier use in Underscore.js template(via json serialization)
      send(:alias_method, method, "#{method}?")
    end
  end

  def do_record?
    !!recorded_purchase_price
  end

  def do_livestream?
    !!livestream_purchase_price
  end

  def do_immerssive?
    !!immersive_purchase_price
  end

  def multisearch_reindex
    if Rails.env.test?
      begin
        update_pg_search_document
      rescue Errno::ECONNREFUSED => e
        Rails.logger.warn e.message
      end
    else
      IndexSession.perform_async(id)
    end
    channel.multisearch_reindex
    records.each(&:multisearch_reindex)
  end

  def invited_co_presenter_status(presenter)
    if presenter.persisted? && (presentership = session_invited_immersive_co_presenterships.select(:status).where(presenter: presenter).first)
      presentership.status
    else
      ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
    end
  end

  def invited_participant_status(participant)
    if participant.persisted? && (participantship = session_invited_immersive_participantships.select(:status).where(participant: participant).first)
      participantship.status
    else
      ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
    end
  end

  # @return [Float]
  def potential_revenue_from
    Rails.cache.fetch("potential_revenue_from/#{cache_key}") do
      result = 0.0

      immersive_participants_count = immersive_participants.count

      if immersive_delivery_method? && immersive_participants_count.positive?
        result += (immersive_participants_count * immersive_purchase_price.to_f) * revenue_split
      end

      if livestream_delivery_method?
        result += livestreamers.count * livestream_purchase_price.to_f * revenue_split
      end

      if recorded_delivery_method?
        result += recorded_members.count * recorded_purchase_price.to_f * revenue_split
      end

      result
    end
  end

  def category
    @category ||= channel.category
  end

  # @return [Float]
  def potential_revenue_to
    Rails.cache.fetch("potential_revenue_to/#{cache_key}") do
      result = 0.0

      # NOTE: - rather complicated condition is needed because otherwise it will display
      # negative potential revenue for completely free session
      # if !completely_free? \
      if status.to_s != Session::Statuses::REQUESTED_FREE_SESSION_APPROVED \
          && status.to_s != Session::Statuses::REQUESTED_FREE_SESSION_REJECTED \
          && status.to_s != Session::Statuses::REQUESTED_FREE_SESSION_PENDING

        if immersive_delivery_method? && !immersive_free
          result += (max_number_of_immersive_participants * immersive_purchase_price.to_f) * revenue_split
        end

        if livestream_delivery_method? && !livestream_free
          result += livestreamers.count * livestream_purchase_price.to_f * revenue_split
        end
      end

      if recorded_delivery_method? && !recorded_free
        result += recorded_members.count * recorded_purchase_price.to_f * revenue_split
      end

      result
    end
  end

  def self.organizers_all_or_by_ids(string_ids = nil)
    ids = string_ids.to_s.split(',').select { |i| i.to_i.to_s == i }
    ids.empty? ? where(nil) : joins(channel: :presenter).where({ presenters: { user_id: ids } })
  end

  def belongs_to_listed_channel?
    !!belongs_to_listed_channel
  end

  def belongs_to_listed_channel
    channel.listed?
  end

  def notify_unnotified_invited_participants
    SessionJobs::NotifyUnnotifiedInvitedParticipantsJob.perform_async(id)
  end

  def primary_record
    @primary_record ||= records.where(show_on_profile: true).where(status: Video::Statuses::DONE).first
  end

  def invalidate_nearest_abstract_session_cache_for_everyone_involved
    ([organizer] \
      + session_participations.collect(&:user) \
      + livestreamers.collect(&:user) \
      + session_co_presenterships.collect(&:user)).compact.each(&:invalidate_nearest_abstract_session_cache)
  end

  def invalidate_purchased_session_cache_for_everyone_involved
    ([organizer] \
      + session_participations.collect(&:user) \
      + livestreamers.collect(&:user) \
      + session_co_presenterships.collect(&:user)).compact.each do |user|
      user.invalidate_purchased_session_cache(id)
    end
  end

  # this method is used by fullCalendar js plugin, it needs data in proper format
  def as_icecube_hash
    {
      title: title,
      start: start_at.iso8601,
      end: duration.minutes.since(start_at).iso8601,
      absolute_path: absolute_path
    }
  end

  def is_not_owner?(pid)
    channel.channel_invited_presenterships.exists?(presenter_id: pid)
  end

  def stream_m3u8_url
    ffmpegservice_account.stream_m3u8_url
  rescue StandardError
    ''
  end

  def recreate_urls
    update_short_urls
    SessionJobs::SlugUpdated.perform_async(id)
  end

  def webrtcservice_channel_id
    ChatChannel.find_by(session_id: id)&.webrtcservice_id
  end

  def is_fake?
    fake? || channel&.is_fake? || presenter&.user&.fake?
  end

  def concurrent_immersive_participants_count
    Room.where.not(status: 'closed', id: room&.id)
        .where('(actual_start_at::timestamp , actual_end_at::timestamp) overlaps (:start_at::timestamp ,:end_at::timestamp)',
               start_at: start_at,
               end_at: end_at)
        .preload(:abstract_session).sum { |r| r.abstract_session.immersive_delivery_method? ? r.abstract_session.max_number_of_immersive_participants.to_i : 0 }
  end

  def service_status_up?
    service_status == 'up'
  end

  def update_comments_count
    return 0 if destroyed?

    count = comments.count
    update_attribute(:comments_count, count)
    count
  end

  def unique_view_group_start_at
    created_at&.utc
  end

  private

  def build_waiting_list
    build_session_waiting_list
  end

  def autoassign_main_wa
    self.ffmpegservice_account = organization.find_or_assign_wa(user_id: presenter.user_id, service_type: service_type)
  end

  # NOTE: do not delete this method
  # it is needed for backward compatibility with friendly_id so that you don't need to patch it
  # #normalize_friendly_id is where magic happens
  def friendly_id_slug_candidate
    'whatever'
  end

  def should_generate_new_friendly_id?
    new_record? || slug.blank? || channel_id_changed? || title_changed? || start_at_changed? || (slug.count('/') < 2)
  end

  # fixes #1393
  # "Notify Me" for upcoming channels
  def send_notifications
    UpcomingChannelNotificationMembership.where(channel: channel).each do |upnm|
      ChannelMailer.notify_about_1st_published_session(channel_id, upnm.user_id).deliver_later
    end
  end

  def first_session_in_presentattion_just_got_published?
    just_got_published? && channel.sessions.published.count == 1
  end

  def set_default_status
    self.status = 'unpublished' if status.blank?
  end

  def schedule_accounting_closing
    SidekiqSystem::Schedule.remove(SessionAccounting, id)

    time = duration.to_i.minutes.since(start_at)
    SessionAccounting.perform_at(time, id)
  end

  def checked_delivery_methods_are_present
    if @immersive && immersive_purchase_price.blank?
      errors.add(:immersive_purchase_price, :blank)
    end
    if @livestream && livestream_purchase_price.blank?
      errors.add(:livestream_purchase_price, :blank)
    end
    if @record && recorded_purchase_price.blank?
      errors.add(:recorded_purchase_price, :blank)
    end
  end

  def published_notify_followers
    # find all changes by TEMPORARYDISABLE
    # channel.subscribers.each do |subscriber_user|
    #   if AbilityLib::Legacy::NonAdminCrudAbility.new(subscriber_user).can?(:read, self)
    #     SessionMailer.published_session_from_channel_you_follow(id, subscriber_user.id).deliver_later
    #   end
    # end

    # organizer.user_followers.each do |follower_user|
    #   if AbilityLib::Legacy::NonAdminCrudAbility.new(follower_user).can?(:read, self)
    #     SessionMailer.published_session_from_user_you_follow(id, follower_user.id).deliver_later
    #   end
    # end
  end

  def just_got_published?
    saved_change_to_status? && status == Session::Statuses::PUBLISHED
  end

  def has_invited_participants?
    # we don't care about rejected invites at this point
    statuses = [ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING,
                ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED]

    session_invited_immersive_participantships.where(status: statuses).present? || session_invited_livestream_participantships.where(status: statuses).present?
  end

  def recurring_settings_limit
    # Validate only root session
    return true if recurring_id.present?
    return true if channel.organization.split_revenue?

    start_at_limit = channel.organization.user.service_subscription&.current_period_end
    if start_at_limit.nil?
      errors.add(:recurring_settings, 'Out of subscription start at limit')
      return false
    end
    settings = recurring_settings
    if settings[:active].present?
      days_of_week = settings[:days].is_a?(Array) ? settings[:days] : Session::DAYS_OF_WEEK
      start_times = []
      (1..150).each do |i|
        current_time = start_at + i.day
        if settings[:until] == 'date'
          break if current_time > Date.strptime(settings[:date], '%m/%d/%Y')
        elsif start_times.count >= settings[:occurrence].to_i
          break
        end
        start_times << current_time if days_of_week.include?(current_time.strftime('%A').downcase)
        if start_times.last && start_times.last > start_at_limit
          errors.add(:recurring_settings, 'Out of subscription start at limit')
          break
        end
      end
    end
    true
  end

  def at_least_one_delivery_method
    if !immersive_delivery_method? && !livestream_delivery_method? && !recorded_delivery_method?
      errors.add(:immersive_type, 'At least one delivery method has to be chosen')
    end
  end

  def sanitize_custom_description_field_value
    self.custom_description_field_value = Html::Parser.new(custom_description_field_value).wrap_urls.process_links.remove_scripts.to_s
    self.description = Html::Parser.new(description).wrap_urls.process_links.remove_scripts.to_s
  end

  def normalize_if_one_on_one
    self.max_number_of_immersive_participants = 1 if immersive_type == Session::ImmersiveTypes::ONE_ON_ONE
    self.min_number_of_immersive_and_livestream_participants = 1 if immersive_type == Session::ImmersiveTypes::ONE_ON_ONE
  end

  def custom_description_field_value_text_length
    length = Nokogiri::HTML.parse(custom_description_field_value).inner_text.length
    if length > LONG_TEXTAREA_MAX_LENGTH
      errors.add(:custom_description_field_value, :too_long, count: LONG_TEXTAREA_MAX_LENGTH)
    end
  end

  def check_if_duration_is_available
    unless valid_durations.include?(duration)
      errors.add(:duration, :inclusion, value: duration)
    end
  end

  def remove_videos_from_multisearch
    records.each do |video|
      video.pg_search_document&.destroy
    end
  end

  def cover_dimensions_and_size_validity
    # because of invalid filetype
    # just exit here because it is validated by checking extension_white_list
    return if cover.path.nil?

    if cover.file.size.to_f > 10.megabytes.to_f
      errors.add(:cover, "Thumbnail #{cover.file.original_filename} should be a maximum size of 10Mb")
      return
    end

    begin
      magick_image = MiniMagick::Image.open(cover.path)

      if magick_image.width < 415 || magick_image.height < 115
        errors.add(:cover, "Thumbnail #{cover.file.original_filename} should be 415x115px minimum")
      end
    rescue StandardError => e
      Rails.logger.info e.message
    end
  end

  def check_concurrent_immersive_participants
    concurrent_participants_count = concurrent_immersive_participants_count
    return if (concurrent_participants_count + max_number_of_immersive_participants.to_i) < 2000

    errors.add(:concurrent_interactive_participants, 'count exceeds the limit')
    Airbrake.notify('concurrent_immersive_participants_count: limit reached. Session update failed',
                    parameters: {
                      session: as_json({ only: %i[id start_at duration pre_time max_number_of_immersive_participants service_type],
                                         methods: [:always_present_title] }),
                      concurrent_participants_count: concurrent_participants_count,
                      concurrent_participants_total: (concurrent_participants_count + max_number_of_immersive_participants)
                    })
  end

  def check_business_subscription
    unless AbilityLib::OrganizationAbility.new(organizer).can?(:create_session_by_business_plan, channel.organization)
      errors.add(:business_plan, I18n.t('controllers.sessions.business_plan_error'))
      return
    end
  end

  def switch_service_type_validation
    errors.add(:service_type, I18n.t('models.session.errors.switch_type_after_start')) if started?
  end

  def cable_notification_service_status_changed
    return if room.blank?

    event = "livestream-#{service_status}"
    stream_url = service_status_up? ? ffmpegservice_account&.hls_url : nil
    PrivateLivestreamRoomsChannel.broadcast_to room, event: event,
                                                     data: { active: room.active?, stream_url: stream_url }
    PublicLivestreamRoomsChannel.broadcast_to room, event: event, data: { active: room.active? }
    SessionsChannel.broadcast event, { session_id: id, active: room.active? }
  end

  def cable_notification_allow_chat_changed
    return if room.blank?

    if allow_chat
      PresenceImmersiveRoomsChannel.broadcast_to(room, { event: 'enable-chat', data: { users: 'all', session_id: id } })
      PrivateLivestreamRoomsChannel.broadcast_to(room, { event: 'enable-chat', data: { users: 'all', session_id: id } })
      PublicLivestreamRoomsChannel.broadcast_to(room, { event: 'enable-chat', data: { users: 'all', session_id: id } })
    else
      PresenceImmersiveRoomsChannel.broadcast_to(room,
                                                 { event: 'disable-chat', data: { users: 'all', session_id: id } })
      PrivateLivestreamRoomsChannel.broadcast_to(room,
                                                 { event: 'disable-chat', data: { users: 'all', session_id: id } })
      PublicLivestreamRoomsChannel.broadcast_to(room, { event: 'disable-chat', data: { users: 'all', session_id: id } })
    end
  end
end
