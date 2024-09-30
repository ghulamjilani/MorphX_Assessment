# frozen_string_literal: true
require 'dropbox/repository'

class User < ActiveRecord::Base
  attr_accessor :email_confirmation, :tzinfo, :custom_slug_value, :during_bp_steps, :credit_cards, :paypal_accounts # add render_views spec for registrations#new

  # it is forced only when user becomes a presenter and needs to choose one
  # timezone explicitely
  attr_accessor :force_manually_set_timezone_validation

  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions
  include ModelConcerns::User::ParticipateInConference
  include ModelConcerns::User::HasConfigurableCoefficients
  include ModelConcerns::User::HasChannels
  include ModelConcerns::User::HasOrganizationMemberships
  include ModelConcerns::User::HasCredentials
  include ModelConcerns::User::HasServiceSubscription

  include ModelConcerns::User::ActsAsOmniauthUser
  include ModelConcerns::User::ActsAsWishlistOwner
  include ModelConcerns::User::HasNotificationCenter
  include ModelConcerns::User::HasFfmpegserviceAccounts

  include RailsSettings::Extend
  include ModelConcerns::ActsAsFollowable

  include ModelConcerns::BelongsToTimezone
  include ModelConcerns::HasShortUrl

  include ModelConcerns::User::PgSearchable
  include ModelConcerns::Trackable

  include ModelConcerns::User::EmailInvitable
  include ModelConcerns::User::UsesSignupTokens
  include ModelConcerns::Shared::Viewable
  include ModelConcerns::Shared::HasPromoWeight
  include ModelConcerns::Shared::HasLists

  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  acts_as_token_authenticatable

  # for likes
  acts_as_votable
  include ModelConcerns::User::ActsAsVoter

  acts_as_follower
  ratyrate_rater
  acts_as_messageable

  SHARE_IMAGE_WIDTH = 280
  SHARE_IMAGE_HEIGHT = 280

  delegate :dropbox_asset, :dropbox_assets, to: :dropbox_repo

  has_one :image, class_name: 'UserImage', dependent: :destroy

  has_one :presenter, dependent: :destroy
  has_one :participant, dependent: :destroy

  has_many :stripe_connect_accounts, class_name: 'StripeDb::ConnectAccount', dependent: :destroy
  has_one :user_account, autosave: false, dependent: :destroy, inverse_of: :user # created when user applies for participant/presenter role
  has_one :organization, autosave: false, dependent: :destroy # created when user of business type applies for participant role
  has_one :session_setting

  has_many :mind_body_db_staffs, class_name: 'MindBodyDb::Staff', foreign_key: 'user_id'

  alias_attribute :account, :user_account

  has_many :bookings, class_name: 'Booking::Booking', dependent: :destroy
  has_many :booking_slots, class_name: 'Booking::BookingSlot', dependent: :destroy
  has_many :requested_bookings, through: :booking_slots, source: :bookings
  has_many :todo_achievements, dependent: :destroy
  has_many :payment_transactions, dependent: :destroy
  has_many :log_transactions, dependent: :destroy
  has_many :pending_refunds, dependent: :destroy
  has_many :referrals, foreign_key: 'master_user_id', dependent: :destroy
  has_many :referral_codes, dependent: :destroy
  has_many :contacts, foreign_key: 'for_user_id', dependent: :destroy
  has_many :videos, dependent: :destroy
  has_many :stream_previews, dependent: :destroy
  has_many :blog_posts, class_name: 'Blog::Post', dependent: :destroy
  has_many :blog_comments, class_name: 'Blog::Comment', dependent: :destroy
  has_many :reviews_made, class_name: 'Review', dependent: :destroy
  has_many :comments_made, class_name: 'Comment', dependent: :destroy

  has_many :questions, dependent: :destroy

  has_many :combined_notification_settings, dependent: :destroy
  has_many :webrtcservice_messages, dependent: :destroy
  has_many :authy_records, dependent: :destroy

  has_many :session_reminders, dependent: :destroy
  has_many :shared_lists, class_name: 'Shop::List', through: :attached_lists, source: :list
  has_many :subscriptions, dependent: :destroy, inverse_of: :user
  has_many :free_subscriptions, class_name: 'FreeSubscription', dependent: :destroy

  has_many :payouts
  has_many :payout_methods
  has_many :user_logs
  has_many :views_made, class_name: 'View', inverse_of: :user, dependent: :delete_all
  has_many :auth_tokens, class_name: 'Auth::UserToken', dependent: :delete_all
  has_many :im_conversation_participants, class_name: 'Im::ConversationParticipant', as: :abstract_user, dependent: :destroy
  # has_many :im_messages, class_name: 'Im::Message', through: :im_conversation_participants
  has_many :affiliate_everflow_transactions, class_name: 'Affiliate::Everflow::Transaction', dependent: :destroy
  has_many :opt_in_modal_submits, class_name: 'MarketingTools::OptInModalSubmit', foreign_key: :user_uuid, primary_key: :uuid, dependent: :destroy
  has_many :document_members, dependent: :destroy
  has_many :documents, through: :document_members
  has_many :recording_members, through: :participant
  has_many :purchased_recordings, through: :recording_members, class_name: 'Recording', source: :recording
  has_many :recorded_members, through: :participant
  has_many :purchased_vods, through: :recorded_members, class_name: 'Session', source: :abstract_session, source_type: 'Session'

  has_many_documents :activities_made, as: :owner, class_name: '::Log::Activity', dependent: :destroy
  has_many_documents :related_activities, as: :recipient, class_name: '::Log::Activity', dependent: :destroy

  belongs_to :parent_organization, class_name: 'Organization', inverse_of: :child_users,
                                   foreign_key: 'parent_organization_id'
  belongs_to :current_organization, class_name: 'Organization', foreign_key: :current_organization_id

  accepts_nested_attributes_for :user_account, update_only: true
  accepts_nested_attributes_for :image, update_only: true
  accepts_nested_attributes_for :organization
  accepts_nested_attributes_for :contacts, allow_destroy: true

  devise :confirmable,
         :database_authenticatable,
         :invitable,
         :omniauthable,
         :recoverable,
         :registerable,
         :rememberable,
         :trackable,
         :validatable, password_length: Rails.application.credentials.backend.dig(:initialize, :security, :user_password, :min_length)..Rails.application.credentials.backend.dig(:initialize, :security, :user_password, :max_length)

  enum platform_role: {
    regular_user: 0,
    service_admin: 1,
    platform_owner: 2
  }

  def active_for_authentication?
    return false if deleted?

    super
  end

  def organizer
    self
  end

  def remember_me
    true
  end

  module Genders
    MALE = 'male'
    FEMALE = 'female'
    HIDDEN = 'hidden'
    ALL = %w[Male Female Hidden].freeze
  end

  module TimeFormats
    HOUR_12 = '12hour'
    HOUR_24 = '24hour'
  end

  module PublicDisplayNameSources
    DISPLAY_NAME = 'display_name'
    FULL_NAME = 'full_name'
  end

  can_skip_validation_for :birthdate,
                          :email,
                          :first_name,
                          :gender,
                          :last_name

  # @see Devise::Models::Validatable
  def email_required?
    !skip_email_validation?
  end

  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }, unless: :skip_first_name_validation?
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }, unless: :skip_last_name_validation?
  validates :display_name, presence: true # , uniqueness: true
  validates :gender, presence: true, inclusion: { in: [Genders::MALE, Genders::FEMALE, Genders::HIDDEN] },
                     unless: proc { |user| user.skip_gender_validation? || Rails.application.credentials.global[:skip_gender_and_birthdate] }
  validates :birthdate, presence: true, unless: proc { |user| user.skip_birthdate_validation? || Rails.application.credentials.global[:skip_gender_and_birthdate] }
  validate :age_by_birthdate, unless: proc { |user| user.skip_birthdate_validation? || Rails.application.credentials.global[:skip_gender_and_birthdate] }
  validates :time_format, presence: true, inclusion: { in: [TimeFormats::HOUR_12, TimeFormats::HOUR_24] }
  validates :public_display_name_source, presence: true,
                                         inclusion: { in: [PublicDisplayNameSources::DISPLAY_NAME, PublicDisplayNameSources::FULL_NAME] }, on: :update

  validates :manually_set_timezone, inclusion: { in: available_timezones.map { |tz| tz.tzinfo.name } }, if: lambda { |u|
    u.manually_set_timezone == '' || (u.force_manually_set_timezone_validation && u.manually_set_timezone_changed?)
  }
  validates :authentication_token, presence: true, uniqueness: true

  validate :password_validation, on: %i[create update], if: proc { |user| !user.password.nil? }

  # NOTE: if you update this inclusion condition, review app/views/service_admin_panel/sessions/_form.html.erb first
  validates :can_create_sessions_with_max_duration, inclusion: { in: 15..420 }, allow_blank: true # because ffmpegservice can record max 8 hours

  validates :affiliate_signature, uniqueness: true, allow_blank: true, allow_nil: true
  validates :current_organization_id, inclusion: { in: lambda { |u|
    u.all_organizations.pluck(:id)
  } }, if: :current_organization_id?

  before_validation :truncate_all_the_fiels
  before_validation :set_display_name, on: :create

  # fixes https://github.com/plataformatec/devise/issues/1639
  before_create :remember_value
  after_create :pick_timezone
  after_create :update_short_urls

  after_update :notify_preview_purchase_modal, if: :just_got_confirmed?

  after_commit on: :create do
    if invited_by.present? && invited_by.is_a?(User) && (User.where(invited_by: invited_by).count >= 5)
      TodoAchievement.find_or_create_by(type: TodoAchievement::Types::REFERRED_FIVE_FRIENDS, user: invited_by)
    end
  end

  after_commit :invalidate_cache, if: :saved_change_to_public_display_name_source?
  after_commit :recreate_urls, on: :update, if: proc { |obj| obj.slug.present? && obj.saved_change_to_slug? }

  def self.is_confirmed(value)
    case value
    when 'yes'
      where.not(confirmed_at: nil)
    when 'no'
      where(confirmed_at: nil)
    end
  end

  def self.organization_owner(value)
    case value
    when 'yes'
      joins(:organization)
    when 'no'
      joins('LEFT JOIN organizations ON organizations.user_id = users.id').where(organizations: { id: nil })
    end
  end

  def self.user_type(value)
    case value
    when 'regular_user'
      regular_users
    when 'service_admin'
      service_admins
    when 'platform_owner'
      platform_owners
    end
  end

  def self.ransackable_scopes(_auth_object = nil)
    %i[is_confirmed organization_owner user_type]
  end

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :not_confirmed, -> { where(confirmed_at: nil) }

  scope :not_fake, -> { where('users.fake IS FALSE') }
  scope :not_deleted, -> { where('users.deleted IS FALSE') }
  scope :for_home_page, -> { where('users.show_on_home IS TRUE') }

  scope :with_follows_count, lambda {
    select('users.*, COUNT(followings) AS following_users_count, COUNT(followers) AS count_user_followers')
      .joins("LEFT JOIN follows AS followings ON followings.follower_id = users.id AND followings.follower_type = 'User' AND followings.blocked = 'f'")
      .joins("LEFT JOIN follows AS followers ON followers.followable_id = users.id AND followers.followable_type = 'User' AND followers.blocked = 'f'")
      .group('users.id, follows.created_at')
  }

  scope :regular_users, -> { where(platform_role: :regular_user) }
  scope :service_admins, -> { where(platform_role: :service_admin) }
  scope :platform_owners, -> { where(platform_role: :platform_owner) }

  def as_json(options)
    hash = {
      has_booking_slots: has_booking_slots?,
      avatar_url: avatar_url
    }
    super(options).merge(hash)
  end

  def following_users
    following_by_type('User').order('follows.created_at DESC')
  end

  def following_users_count
    if attributes.has_key?(__method__.to_s)
      attributes[__method__.to_s]
    else
      super
    end
  end

  def has_booking_slots?
    booking_slots.not_deleted.present?
  end

  def booking_available?
    return false unless has_booking_slots?

    free_slots = false
    booking_slots.not_deleted.each do |bs|
      rules = JSON.parse(bs.slot_rules)
      weeks = JSON.parse(bs.week_rules)
      next if weeks.blank?

      bs.booking_prices.each do |price|
        date = Time.now.in_time_zone(bs.user.timezone)
        while date.strftime('%-V').to_i <= weeks.max
          rule_day = date.strftime('%A')
          rule = rules.detect { |r| r['name'] == rule_day }

          if rule['scheduler'].present?
            rule['scheduler'].each do |s|
              date = date.change({ hour: s['start'].split(':').first, min: s['start'].split(':').last, sec: 0 })
              date_end = date.change({ hour: s['end'].split(':').first, min: s['end'].split(':').last, sec: 0 })
              while (date + price.duration.minutes) <= date_end
                booking = bs.bookings.new(start_at: date, end_at: date + price.duration.minutes, status: :approved, user_id: bs.user.id, duration: price.duration, booking_price_id: price.id)
                if booking.valid?
                  free_slots = true
                  break
                end
                date += price.duration.minutes
              end
            end
          end

          break if free_slots

          date += 1.day
        end
      end
    end
    free_slots
  end

  def setup_affiliate_signature
    return if affiliate_signature.present? || !id

    signature = "#{SecureRandom.hex(6)}.#{id}"
    update(affiliate_signature: signature)
  end

  def most_known_because_of_channel_cache_key
    "#{__method__}/#{cache_key}"
  end

  # this method is used on home page and search results in tiles
  # where we need to display what's this presenter is all about
  # @return [Channel]
  def most_known_because_of_channel
    return if channels.empty?

    # NOTE: you may want to adjust this logic to take popularity in account later

    Rails.cache.fetch(most_known_because_of_channel_cache_key) do
      channels.publicly_visibile_to_general_audience.order(updated_at: :desc).first or raise "check whether user #{id} has to be displayed here at all first"
    end
  end

  def current_phone_is_approved?
    authy_records
      .where(cellphone: user_account.cellphone, country_code: user_account.country_code)
      .exists?(status: AuthyRecord::Statuses::APPROVED)
  end

  def notify_about_invitation
    blocking_notifications = BlockingNotificationPresenter.new(self, AbilityLib::Legacy::AccountingAbility.new(self))
    flashbox_html = blocking_notifications.to_s

    UsersChannel.broadcast_to(self, event: 'new-flashbox',
                                    data: { flashbox: flashbox_html, notifications: blocking_notifications.notifications })
  end

  # @return [Integer]
  def free_sessions_without_admin_approval_left_count
    channel_ids = channels.pluck(:id)
    preliminary_result = can_publish_n_free_sessions_without_admin_approval.to_i - Session
                         .where(channel_id: channel_ids)
                         .where('immersive_purchase_price = 0 OR livestream_purchase_price = 0').count

    preliminary_result.positive? ? preliminary_result : 0
  end

  # IMD-276
  # Allow to create max 10 free private sessions by default
  # @return [Integer]
  def free_private_sessions_without_admin_approval_left_count
    channel_ids = channels.pluck(:id)
    allowed_count = can_publish_n_free_sessions_without_admin_approval.to_i.zero? ? 10 : can_publish_n_free_sessions_without_admin_approval.to_i
    preliminary_result = allowed_count - Session
                         .where(channel_id: channel_ids, private: true)
                         .where(%(sessions.immersive_purchase_price = 0 OR sessions.livestream_purchase_price = 0)).count

    preliminary_result.positive? ? preliminary_result : 0
  end

  # Allow to create max 10 free private interactive sessions by default
  # @return [Integer]
  def free_private_interactive_without_admin_approval_left_count
    channel_ids = channels.pluck(:id)
    allowed_count = if can_publish_n_free_sessions_without_admin_approval.to_i.zero?
                      begin
                        SystemParameter.free_private_interactive_count.to_i
                      rescue StandardError
                        10
                      end
                    else
                      can_publish_n_free_sessions_without_admin_approval.to_i
                    end
    allowed_count - Session.where(channel_id: channel_ids, private: true, immersive_purchase_price: 0, status: 'published').count
  end

  # @param - model - could be instance of User or Organization class
  # @return [String]
  def fast_following_cache_key(model)
    "#{__method__}/#{id}/#{model.class.to_s.downcase}/#{model.id}"
  end

  # this is regular acts_as_follower#following? but with caching
  def fast_following?(followable)
    Rails.cache.fetch(fast_following_cache_key(followable)) { following?(followable) }
  end

  def toggle_follow(followable)
    if (is_follow = following?(followable))
      stop_following(followable)
    else
      follow(followable)
    end
    clear_follow_cache(followable)
    return !is_follow
  end

  def clear_follow_cache(followable)
    followable.touch # so that home page tiles are updated as well
    Rails.cache.delete fast_following_cache_key(followable)
  end

  def email_with_display_name
    "#{email} - #{display_name}"
  end

  def timezone
    @timezone ||= (manually_set_timezone ? manually_set_timezone : 'America/Chicago')
  end

  # @return [Array]
  # example respone: [{"user_id"=>1, "id"=>1, type: "Share a Session", "created_at"=>Sun, 26 Jul 2015 13:57:39 UTC +00:00}]
  def todo_achievements_as_hashes
    Rails.cache.fetch("#{__method__}/#{cache_key}") do
      todo_achievements.order(created_at: :asc).collect(&:attributes)
    end
  end

  def average(dimension)
    # no rating for user without channels or organization
    return if organization.blank? && channels.blank?

    OpenStruct.new.tap do |ostruct|
      ratings = channels.collect do |channel|
        cached_average = channel.average dimension
        avg = cached_average ? cached_average.avg : 0
        avg
      end.select(&:positive?)

      mean = if ratings.blank?
               0
             else
               ratings.inject(0) { |sum, x| sum += x } / ratings.size
             end

      ostruct.avg = mean
    end
  end

  def invalidate_nearest_abstract_session_cache
    Rails.cache.delete("nearest_abstract_session/#{cache_key}")
  end

  def invalidate_participate_in_session_cache(session_id)
    Rails.cache.delete("participate_in_session/#{session_id}/#{id}")
  end

  def invalidate_view_in_session_cache(session_id)
    Rails.cache.delete("view_in_session/#{session_id}/#{id}")
  end

  def invalidate_purchased_session_cache(session_id)
    invalidate_view_in_session_cache(session_id)
    invalidate_participate_in_session_cache(session_id)
  end

  def participate_in?(session_id)
    Rails.cache.fetch("participate_in_session/#{session_id}/#{id}") do
      SessionParticipation.exists?(session_id: session_id, participant_id: participant_id)
    end
  end

  def view_in?(session_id)
    Rails.cache.fetch("view_in_session/#{session_id}/#{id}") do
      Livestreamer.exists?(session_id: session_id, participant_id: participant_id)
    end
  end

  def purchased_session?(session_id)
    participate_in?(session_id) || view_in?(session_id)
  end

  # used in "Next live event" button in the header
  # #return - object of Session type
  def nearest_abstract_session
    Rails.cache.fetch("nearest_abstract_session/#{cache_key}") do
      Session.distinct.joins(:room)
             .joins('LEFT JOIN session_participations ON session_participations.session_id = sessions.id')
             .joins('LEFT JOIN livestreamers ON livestreamers.session_id = sessions.id')
             .joins('LEFT JOIN session_co_presenterships ON livestreamers.session_id = sessions.id')
             .joins('LEFT JOIN participants ON session_participations.participant_id = participants.id')
             .joins('LEFT JOIN room_members ON rooms.id = room_members.room_id AND participants.user_id::varchar = room_members.abstract_user_id AND room_members.abstract_user_type = \'User\' AND room_members.banned = TRUE')
             .upcoming.not_cancelled.not_finished.not_archived.published
             .where.not(rooms: { status: [Room::Statuses::CLOSED, Room::Statuses::CANCELLED] })
             .where(%(room_members.banned IS NOT TRUE))
             .where(%(sessions.presenter_id = :presenter_id OR session_participations.participant_id = :participant_id OR livestreamers.participant_id = :participant_id OR session_co_presenterships.presenter_id = :presenter_id),
                    participant_id: participant_id, presenter_id: presenter_id)
             .order(start_at: :asc).limit(1).first
    end
  end

  def upcoming_sessions
    ids = Session.distinct.joins(:room)
                 .joins('LEFT JOIN session_participations ON session_participations.session_id = sessions.id')
                 .joins('LEFT JOIN livestreamers ON livestreamers.session_id = sessions.id')
                 .joins('LEFT JOIN session_co_presenterships ON livestreamers.session_id = sessions.id')
                 .joins('LEFT JOIN channels ON channels.id = sessions.channel_id')
                 .joins('LEFT JOIN subscriptions ON subscriptions.channel_id = channels.id AND subscriptions.enabled = TRUE')
                 .joins('LEFT JOIN stripe_plans ON stripe_plans.channel_subscription_id = subscriptions.id')
                 .joins('LEFT JOIN stripe_subscriptions ON stripe_subscriptions.stripe_plan_id = stripe_plans.id')
                 .upcoming.not_cancelled.not_finished.not_archived.published
                 .where.not(rooms: { status: [Room::Statuses::CLOSED, Room::Statuses::CANCELLED] })
                 .where(%{sessions.presenter_id = :presenter_id OR session_participations.participant_id = :participant_id OR livestreamers.participant_id = :participant_id OR session_co_presenterships.presenter_id = :presenter_id OR (stripe_subscriptions.user_id = :user_id AND stripe_subscriptions.status = 'active')},
                        participant_id: participant_id, presenter_id: presenter_id, user_id: id).pluck(:id)
    # Split query into two queries because '.distinct' causes pg to sort all records by all fields, not just single one specified in query which decreases performance
    Session.where(id: ids).order(start_at: :asc)
  end

  def feed_sessions
    ids = Session.distinct.joins(:room)
                 .joins('LEFT JOIN session_participations ON session_participations.session_id = sessions.id')
                 .joins('LEFT JOIN livestreamers ON livestreamers.session_id = sessions.id')
                 .upcoming.not_cancelled.not_finished.not_archived.published
                 .where.not(rooms: { status: [Room::Statuses::CLOSED, Room::Statuses::CANCELLED] })
                 .where(%(session_participations.participant_id = :participant_id OR livestreamers.participant_id = :participant_id), participant_id: participant_id).pluck(:id)

    Session.where(id: ids).order(start_at: :asc)
  end

  def user_data
    {
      id: id,
      email: email,
      logo: medium_avatar_url,
      full_name: full_name,
      relative_path: relative_path
    }
  end

  def participant_id
    @participant_id ||= participant&.id
  end

  def presenter_id
    @presenter_id ||= presenter&.id
  end

  def organization_id
    @organization_id ||= organization&.id
  end

  # @return [Session]
  def on_demand_sessions
    @on_demand_sessions ||= begin
      _cache_key = "on_demand_sessions/#{id}/#{Room.where(vod_is_fully_ready: true).maximum(:updated_at).to_i}"

      Rails.cache.fetch(_cache_key) do
        Session
          .joins('LEFT OUTER JOIN channels ON channels.id = sessions.channel_id')
          .joins('LEFT OUTER JOIN organizations ON organizations.id = channels.organization_id')
          .joins('LEFT OUTER JOIN rooms ON rooms.abstract_session_id = sessions.id AND rooms.abstract_session_type = \'Session\'')
          .joins('LEFT OUTER JOIN recorded_members ON recorded_members.abstract_session_id = sessions.id') # TODO: FIXME- multiple "ON"?
          .where('sessions.presenter_id = :presenter_id OR recorded_members.participant_id = :participant_id OR channels.presenter_id = :presenter_id OR organizations.user_id = :user_id',
                 presenter_id: presenter_id, participant_id: participant_id, user_id: id)
          .where(rooms: { vod_is_fully_ready: true }).select('DISTINCT ON (sessions.id) sessions.*')
      end
    end
  end

  def raters_count
    ids = Session.where(channel_id: channels.ids).pluck(:id)
    Rate.where(rateable_type: 'Session', dimension: Session::RateKeys::MANDATORY, rateable_id: ids).count
  end

  def owned_replays
    @owned_replays ||= begin
      _cache_key = "owned_replays/#{id}/#{Room.where(vod_is_fully_ready: true).maximum(:updated_at).to_i}"

      Rails.cache.fetch(_cache_key) do
        Session.select('DISTINCT ON (sessions.id) sessions.*').joins(:room).joins(:channel).joins(:records)
               .joins('LEFT OUTER JOIN organizations ON organizations.id = channels.organization_id')
               .where('sessions.presenter_id = :presenter_id OR channels.presenter_id = :presenter_id OR organizations.user_id = :user_id',
                      presenter_id: presenter_id, user_id: id)
               .where(videos: { status: Video::Statuses::DONE })
               .where(rooms: { vod_is_fully_ready: true }).order('sessions.id desc')
      end
    end
  end

  def purchased_replays
    Session.joins(:records).joins(:recorded_participants)
           .where(participants: { user_id: id }, rooms: { vod_is_fully_ready: true })
  end

  # could be cached because what was seen could not be unseen
  def saw?(session)
    _cache_key = "saw_session/#{id}/#{session.id}"

    return true if Rails.cache.read(_cache_key).present?

    if session.views.exists?(user_id: id)
      Rails.cache.write(_cache_key, true)
      true
    else
      false
    end
  end

  after_destroy do
    User.where(invited_by_type: 'User', invited_by_id: id).update_all({ invited_by_type: nil, invited_by_id: nil })

    Mailboxer::Message.where(sender: self).each do |message|
      if message.conversation # because mailboxer seems to have its own callbacks and sometimes message#conversation is nil here
        message.conversation.messages.destroy_all
        message.conversation.destroy
      end
    end
  end

  after_destroy { Referral.where(user_id: id).destroy_all }
  after_destroy { Contact.where(contact_user_id: id).destroy_all }
  after_destroy { Rate.where(rater_id: id).destroy_all }

  def before_create_generic_callbacks_without_skipping_validation
    before_create_generic_callbacks
  end

  def before_create_generic_callbacks_and_skip_validation
    skip_validation_for(*all_validation_skipable_user_attributes.dup.reject { |s| s == :email })

    before_create_generic_callbacks
  end

  # Attempt to find a user by its reset_password_token to reset its
  # password. If a user is found and token is still valid, reset its password and automatically
  # try saving the record. If not user is found, returns a new user
  # containing an error in reset_password_token attribute.
  # Attributes must contain reset_password_token, password and confirmation
  def self.reset_password_by_token_while_skipping_unrelated_validations(attributes = {})
    original_token = attributes[:reset_password_token]
    reset_password_token = Devise.token_generator.digest(self, :reset_password_token, original_token)

    recoverable = find_or_initialize_with_error_by(:reset_password_token, reset_password_token)

    # ADDED
    recoverable.skip_validation_for(*all_validation_skipable_user_attributes.dup.reject { |s| s == :email })
    # ADDED

    if recoverable.persisted?
      if recoverable.reset_password_period_valid?
        recoverable.reset_password(attributes[:password], attributes[:password_confirmation])
      else
        recoverable.errors.add(:reset_password_token, :expired)
      end
    end

    recoverable.reset_password_token = original_token if recoverable.reset_password_token.present?
    recoverable
  end

  def always_present_title
    display_name
  end

  def preview_share_relative_path
    "#{relative_path}/preview_share"
  end

  def share_description
    @share_description ||= Nokogiri::HTML.parse(user_account.try(:bio)).inner_text
  end

  # NOTE: used only in #last_followers_as_json method
  def has_channels
    has_owned_channels?
  end

  def last_followers_as_json(limit = 14)
    user_followers.includes(:image).limit(limit).to_json(only: [:id],
                                                         methods: %i[has_channels public_display_name avatar_url
                                                                     relative_path])
  end

  def last_followings_as_json(limit = 14)
    following_users.includes(:image).limit(limit).to_json(only: [:id],
                                                          methods: %i[has_channels public_display_name avatar_url
                                                                      relative_path])
  end

  def remember_value
    self.remember_token ||= Devise.friendly_token
  end

  def block_from_invitation?
    false
  end

  def full_name
    return public_display_name if first_name.blank? && last_name.blank?

    "#{first_name} #{last_name}"
  end

  def relative_path(suffix = '')
    raw = if friendly_id
            "/#{friendly_id}"
          else
            begin
              skip_validation_for(*all_validation_skipable_user_attributes)
              set_display_name
              save
              result = slug

              if result.present?
                # Airbrake.notify(RuntimeError.new("just fixed blank slug for user"),
                #                 parameters: {
                #                   user: self.inspect
                #                 })
                # slug
              else
                Airbrake.notify(
                  RuntimeError.new(" __ user #{id} does not have #friendly_id. display_name: #{display_name}"),
                  parameters: {
                    user: inspect
                  }
                )
                slug = "user-#{id}"
                save
              end
              "/#{slug}"
            end
          end

    "#{raw}#{suffix}"
  end

  def toggle_like_relative_path
    "#{relative_path}/toggle_like"
  end

  def likes_cache_key
    "likes/#{self.class.to_s.downcase}/#{id}"
  end

  def likes_count
    Rails.cache.fetch(likes_cache_key) do
      result = get_likes.count
      result += channels.sum { |p| p.get_likes.count }
      result
    end
  end

  # NOTE: that's method is for displaying contacts in the following modal:
  # "x of your Facebook friends are already on Immerss, so we've added them to your contact list."
  # this modal is displayed just once per contact/per bulk contact list imported
  def contacts_to_display_in_modal(logger_user_tag)
    @contacts_to_display_in_modal ||= Contact.where(originally_facebook_friend_and_not_seen_yet: true)
                                             .where(for_user_id: id).each { |c| c.seen!(logger_user_tag) }
  end

  def object_label
    if first_name.present? && last_name.present?
      "#{first_name} #{last_name}"
    elsif display_name.present?
      display_name
    else
      "User ##{id}"
    end
  end

  def public_display_name
    if public_display_name_source == PublicDisplayNameSources::DISPLAY_NAME
      display_name
    else
      [first_name, last_name].compact.join(' ') || display_name
    end
  end

  alias_method :share_title, :public_display_name

  # taken from https://github.com/ging/social_stream/blob/12eca97a22a34fb44abd9341c6d25ad14c975c8e/base/app/models/actor.rb#L589
  #
  # @return [Integer]
  def unread_messages_count
    Rails.cache.fetch(unread_messages_count_cache) do
      mailbox.inbox(unread: true).count # only in inbox
      # Mailboxer::Conversation.unread(self).count            # in all folders
    end.to_i
  end

  # this value is passed to UTM.build_params for constructing links in email notifications
  def utm_content_value
    # if that is a Facebook user, it doesn't make sense to prefill Log In modal with his email
    # because he would use FB auth anyways
    _email = identities.blank? ? email : ''

    UtmContentToken.for_user_id_and_email(id, _email)
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

  def reviews_with_comment_cache_key
    "user/#{id}/reviews_with_comment"
  end

  # see channel#reviews
  # see session#reviews
  def reviews_with_comment
    @reviews_with_comment ||= Rails.cache.fetch(reviews_with_comment_cache_key) { fetch_reviews_with_comment }
  end

  def my_referral_code_text
    rc = ReferralCode.where(user: self).last
    if rc.blank? # so that you can skip migration
      create_referral_code
      rc = ReferralCode.where(user: self).last
    end
    rc.code
  end

  def create_referral_code
    Retryable.retryable(tries: 7, on: ActiveRecord::RecordNotUnique) do
      ReferralCode.create!(user: self, code: rand(36**8).to_s(36)) # 4-characters long e.g. 's9fz'
    end
  end

  def has_payment_info?
    stripe_customer_id.present?
  end

  def with_stripe_data!
    raise 'user.stripe_customer_id has to be not-null' unless has_payment_info?

    self.credit_cards ||= stripe_customer_sources
    self
  end

  def stripe_customer
    return nil unless has_payment_info?

    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  end

  def find_stripe_customer_source(stripe_source_id)
    return nil unless has_payment_info?

    Stripe::Customer.retrieve_source(stripe_customer_id, stripe_source_id)
  end

  def stripe_customer_sources(limit = 100)
    return [] unless has_payment_info?

    Stripe::Customer.list_sources(stripe_customer_id, { object: 'card', limit: limit })[:data]
  end

  def default_credit_card
    return unless has_payment_info?

    find_stripe_customer_source(stripe_customer.default_source) if stripe_customer.default_source.present?
  end

  def in_waiting_list?(session)
    Rails.cache.fetch("in_waiting_list/#{cache_key}/#{session.id}") do
      session.session_waiting_list.session_waiting_list_memberships.where(user_id: id).present?
    end
  end

  def my_referral_users
    Referral.where(master_user_id: id).preload(:user).collect(&:user)
  end

  def someones_referral_user?
    Referral.exists?(user: self)
  end

  def receives_notification?(type)
    return false if deleted?

    # aliases
    if type.to_s == 'user_accepted_your_session_invitation_via_web' \
         || type.to_s == 'user_accepted_your_channel_invitation_via_web' \
         || type.to_s == 'user_rejected_your_session_invitation_via_web' \
         || type.to_s == 'user_rejected_your_channel_invitation_via_web'
      return setting_is_on?('user_accepted_or_rejected_your_invitation_via_web')
    end

    # aliases
    if type.to_s == 'user_accepted_your_session_invitation_via_email' \
         || type.to_s == 'user_accepted_your_channel_invitation_via_email' \
         || type.to_s == 'user_rejected_your_session_invitation_via_email' \
         || type.to_s == 'user_rejected_your_channel_invitation_via_email'
      return setting_is_on?('user_accepted_or_rejected_your_invitation_via_email')
    end

    setting_is_on?(type)
  end

  def receives_reminder?(type)
    return false if deleted?

    setting_is_on?(type)
  end

  # Check if all  steps are done
  def network_ready?
    # first step
    user_info_ready? &&
      # second step
      channels.joins(:cover).count.positive? &&
      channel.valid? &&
      # personal channel
      ((channel.presenter_id && user_info_ready?) ||
        # company channel
        (channel.organization_id && company_info_ready? && (channel.presenter_id || channel.presenters.count.positive?)))
  end

  def user_info_ready?
    main_info_ready = first_name.present? && last_name.present? && email.present? && encrypted_password.present?

    return main_info_ready && birthdate.present? && gender.present? unless Rails.application.credentials.global[:skip_gender_and_birthdate]

    main_info_ready
  end

  def channel_ready?
    channel&.valid? && channel&.cover
  end

  def company_info_ready?
    organization&.valid?
  end

  private def setting_is_on?(type)
    unless ModelConcerns::Settings::Notification::ALL.include?(type.to_s)
      raise ArgumentError, type.inspect
    end

    result = settings.where(var: type).last.try(:value)
    (result.nil? && !type.to_s.ends_with?('_via_sms')) || result == '1' # nil => by default ON/receives newly added notification setting
  end

  def new_notifications_count_cache_key
    "new_notifications_count/#{id}"
  end

  def unread_messages_count_cache
    "unread_messages_count/#{id}"
  end

  # param model - instance of Session classes
  def available_contact_users_for_inviting(model)
    @available_contact_users_for_inviting ||= begin
      exclude = []

      exclude += model.immersive_participants.pluck(:user_id)

      if model.is_a?(Session)
        exclude += User.distinct.joins(:participant)
                       .joins('LEFT JOIN session_invited_immersive_participantships on participants.id = session_invited_immersive_participantships.participant_id')
                       .joins('LEFT JOIN session_invited_livestream_participantships on participants.id = session_invited_livestream_participantships.participant_id')
                       .where('session_invited_immersive_participantships.session_id = :session_id OR session_invited_livestream_participantships.session_id = :session_id', { session_id: model.id })
                       .pluck(:id)
      else
        raise "can not interpret argument #{model.inspect}"
      end

      User.joins('INNER JOIN contacts ON contacts.contact_user_id = users.id')
          .where(contacts: { for_user_id: id })
          .where.not(contacts: { contact_user_id: exclude })
          .order(Arel.sql('LOWER(users.display_name) ASC, users.email ASC'))
    end
  end

  # @return [User]
  def contact_users
    User.joins('INNER JOIN contacts ON contacts.contact_user_id = users.id')
        .where(contacts: { for_user_id: id })
        .order(Arel.sql('LOWER(users.display_name) ASC, users.email ASC'))
  end

  def has_contact?(contact_user_id)
    contacts.exists?(contact_user_id: contact_user_id)
  end

  # NOTE: caching is needed here because otherwise it fails to reliably work for new users
  # #can_receive_abstract_session_invitation_without_invitation_token? is checked 3 times where
  # 1st call returns false and all 2+ calls return true
  def can_receive_abstract_session_invitation_without_invitation_token?
    # giving it enough time to perform all checks and send all delayed mailer templates(email/web/sms)
    Rails.cache.fetch("#{__method__}/#{id}", expires_in: 5.seconds) do
      sign_in_count.positive? ||
        confirmed? ||
        (invitation_sent_at.present? && invitation_accepted_at.present?)
    end
  end

  def mark_as_destroyed
    self.deleted = true
    self.old_email = email
    self.email = ''
    identities.destroy_all
    save
  end

  # @return [IssuedSystemCredit]
  def receive_issued_system_credit!(*args)
    result = participant.issued_system_credits.create!(*args)
    participant.touch if result
    result
  end

  def was_ever_invited_as_co_presenter?
    return false unless persisted?
    return false if friendly_id.blank?

    Rails.cache.fetch("#{__method__}/#{id}/#{SessionInvitedImmersiveCoPresentership.count}/#{ChannelInvitedPresentership.count}") do
      SessionInvitedImmersiveCoPresentership.exists?(presenter: try(:presenter)) ||
        ChannelInvitedPresentership.exists?(presenter: try(:presenter))
    end
  end

  def was_ever_invited_as_participant?
    return false unless persisted?

    participant.present?
  end

  def system_credit_balance
    participant ? participant.system_credit_balance : create_participant!.system_credit_balance
  end

  def presenter_credit_balance
    presenter ? presenter.presenter_credit_balance : create_presenter!.presenter_credit_balance
  end

  # OVERRIDE Devise invitation method for temporary skip of validation
  def accept_invitation!
    skip_validation_for(*all_validation_skipable_user_attributes)
    super
  end

  # OVERRIDE Devise reset_password method for temporary skip of validation
  def reset_password!(new_password, new_password_confirmation)
    skip_validation_for(*all_validation_skipable_user_attributes)
    super
  end

  # just to comply with Mailboxer convention
  def mailboxer_email(*_whatever)
    email
  end

  def small_avatar_url
    (image || build_image).original_image.small.url
  end

  alias_method :pinterest_share_preview_image_url, :small_avatar_url

  def medium_avatar_url
    (image || build_image).original_image.medium.url
  end

  alias_method :avatar_url, :medium_avatar_url

  # wtf? this should be a square but proportions are wrong
  def large_avatar_url
    (image || build_image).original_image.large.url
  end

  alias_method :logo_url, :large_avatar_url
  alias_method :share_image_url, :large_avatar_url

  def am_format?
    time_format.eql? TimeFormats::HOUR_12
  end

  def set_public_display_name_source
    self.public_display_name_source = PublicDisplayNameSources::DISPLAY_NAME
  end

  def set_authentication_token
    10.times do
      hex = SecureRandom.hex
      unless User.exists?(authentication_token: hex)
        self.authentication_token = hex
        break
      end
    end
  end

  def set_display_name
    if display_name.to_s.strip.present? || first_name.to_s.strip.present? || email.present?
      synthetic_display_name = first_name.to_s.strip.present? ? "#{first_name.to_s.strip} #{last_name.to_s.strip}" : email.to_s.split('@')[0]

      if friendly_id_reserved_words.include?(synthetic_display_name)
        synthetic_display_name = if email.present?
                                   email.split('.')[0...-1].join('-').tr('@', '-')
                                 else
                                   'user'
                                 end
      end

      raw_display_name = display_name.to_s.strip.presence || synthetic_display_name
    else
      raw_display_name = 'user'
    end

    self.display_name = raw_display_name

    # exception_callback = Proc.new do |exception|
    #   self.display_name = "#{raw_display_name} #{rand(1000)}"
    # end
    #
    # Retryable.retryable(tries: 7, on: ArgumentError, exception_cb: exception_callback) do
    #   raise ArgumentError if User.find_by_display_name(display_name).present?
    # end
  end

  module Roles
    REGULAR = 'regular'
    PRESENTER = 'presenter'
    PARTICIPANT = 'participant'
  end

  def role
    if organization.present? || organization_memberships_active.exists? || service_subscription.present?
      Roles::PRESENTER
    else
      Roles::PARTICIPANT
    end
  end

  def current_role
    Rails.cache.fetch("user/#{__method__}/#{id}/#{cache_key}") do
      if current_organization&.active_subscription_or_split_revenue? && (current_organization_owner? || current_organization_participant?)
        Roles::PRESENTER
      else
        Roles::PARTICIPANT
      end
    end
  end

  def presenter?
    role.eql? 'presenter'
  end

  def participant?
    role.eql? 'participant'
  end

  def regular?
    role.eql? 'regular'
  end

  def current_organization_owner?
    persisted? && current_organization&.user_id == id
  end

  def dropbox_repo
    @dropbox_repo ||= Dropbox::Repository.new(self)
  end

  def channel_name
    "private-user-#{id}"
  end

  def get_age_restrictions
    if birthdate.blank? || (Time.zone.now - birthdate.to_time) < 18.years
      0
    elsif (Time.zone.now - birthdate.to_time) >= 21.years
      2
    else
      1
    end
  end

  def multisearch_reindex
    if Rails.env.test?
      begin
        update_pg_search_document
      rescue Errno::ECONNREFUSED => e
        Rails.logger.warn e.message
      end
    else
      IndexUser.perform_async(id)
    end
  end

  def earnings
    log_transactions
      .where(type: [LogTransaction::Types::NET_INCOME,
                    LogTransaction::Types::SOLD_CHANNEL_SUBSCRIPTION,
                    LogTransaction::Types::SOLD_CHANNEL_GIFT_SUBSCRIPTION])
  end

  def revenue_percent
    if Rails.application.credentials.global.dig(:service_subscriptions, :enabled) && service_subscription.present?
      service_subscription&.plan_package&.feature_parameters&.by_code(:split_revenue_percent)&.first&.value&.to_i || 100
    else
      profit_margin_percent.to_i
    end
  end

  def current_organization_revenue_percent
    if current_organization.present?
      current_organization.user.revenue_percent
    else
      profit_margin_percent.to_i
    end
  end

  def all_organizations
    Organization.select('DISTINCT ON (organizations.id) organizations.*')
                .joins(%(LEFT JOIN organization_memberships ON organization_memberships.organization_id = organizations.id))
                .where(%(organizations.user_id = :user_id OR organization_memberships.user_id = :user_id AND organization_memberships.status = :status_active), user_id: id, status_active: OrganizationMembership::Statuses::ACTIVE)
                .order(id: :asc, name: :asc)
  end

  # channels that user subscribed to
  def channels_subscriptions
    StripeDb::Subscription.joins(stripe_plan: :channel).where(user_id: id)
                          .where.not(stripe_plans: { channel_subscription_id: nil })
  end

  def recreate_urls
    update_short_urls
    UserJobs::SlugUpdated.perform_async(id)
  end

  def reset_authentication_token!
    update_column(:authentication_token, generate_authentication_token(token_generator))
  end

  def ready_for_wa?
    has_listed_channels?
  end

  def become_creator_link
    step = presenter&.last_seen_become_presenter_step
    case step
    when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP2
      Rails.application.class.routes.url_helpers.wizard_v2_business_path
    when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP3
      Rails.application.class.routes.url_helpers.wizard_v2_channel_path
    when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::DONE
      Rails.application.class.routes.url_helpers.wizard_v2_summary_path
    else
      Rails.application.class.routes.url_helpers.landing_home_path
    end
  end

  def become_creator_title
    step = presenter&.last_seen_become_presenter_step
    case step
    when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP2
      'Complete Business'
    when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP3
      'Complete Channel'
    else
      'START CREATING'
    end
  end

  def active_organization_membership(organization)
    organization_memberships_active.find_by(organization: organization)
  end

  private

  def just_got_confirmed?
    saved_change_to_confirmed_at? && confirmed_at_before_last_save.blank?
  end

  def notify_preview_purchase_modal
    UsersChannel.broadcast_to self, event: 'confirmed', data: { user_id: id }
  end

  def fetch_reviews_with_comment
    return [] if channels.blank?

    ids = Session.where(channel_id: channels.ids).pluck(:id)

    reviews = Review.where(commentable_type: 'Session', commentable_id: ids)

    mandatory_rates = Rate.where(rateable_type: 'Session', dimension: Session::RateKeys::MANDATORY, rateable_id: ids)

    mandatory_rates.group_by(&:rater).select do |_k, v|
      v.size == Session::RateKeys::MANDATORY.size
    end.inject([]) do |result_memo, element|
      result_memo << { rate_created_at: element.last.collect(&:updated_at).max,
                       comment: reviews.detect { |c| c.user_id == element.first.id }.try(:overall_experience_comment),
                       rateable: element.last.first.rateable,
                       stars_quantity: element.last.sum(&:stars) / 2,
                       rater: element.first }
    end.select { |h| h[:comment].present? }.sort_by { |h| h[:rate_created_at] }.reverse
  end

  def before_create_generic_callbacks
    set_default_referral_participant_fee_in_percent
    set_default_revenue_split_coefficient
    set_display_name
    set_public_display_name_source
    set_authentication_token
  end

  # fixes #1210
  def invalidate_cache
    return if organization.blank?

    channel_ids = channels.pluck(:id)
    Session.where(channel_id: channel_ids).update_all(updated_at: Time.now.utc)
  end

  def slug_candidates
    set_display_name if display_name.blank?
    if custom_slug && custom_slug_value
      [
        custom_slug_value,
        [custom_slug_value, id]
      ]
    else
      [
        public_display_name,
        [public_display_name, id]
      ]
    end
  end

  def should_generate_new_friendly_id?
    new_record? || slug.blank? || # if new user or no slug
      (custom_slug && custom_slug_value) || # if user changed his slug manually
      (!custom_slug && (first_name_changed? || last_name_changed? || display_name_changed?))
  end

  def truncate_all_the_fiels
    self.first_name = first_name.strip if first_name.present?
    self.last_name = last_name.strip if last_name.present?
    self.display_name = display_name.strip if display_name.present?
  end

  def age_by_birthdate
    errors.add(:birthdate, 'age must be greater than 12 years') if birthdate && (Time.zone.now - 11.years < birthdate)
  end

  def password_reset_attempt_by_invited_user?
    invited_by.present? && first_name.blank?
  end

  def password_validation
    include_lowercase = Rails.application.credentials.backend.dig(:initialize, :security, :user_password,
                                                                  :include_lowercase)
    if include_lowercase && !password.match(/[a-zа-я]+/)
      errors.add(:password, 'must contain at least one lowercase letter')
    end

    include_uppercase = Rails.application.credentials.backend.dig(:initialize, :security, :user_password,
                                                                  :include_uppercase)
    if include_uppercase && !password.match(/[A-ZА-Я]+/)
      errors.add(:password, 'must contain at least one uppercase letter')
    end

    include_numeric = Rails.application.credentials.backend.dig(:initialize, :security, :user_password,
                                                                :include_numeric)
    if include_numeric && !password.match(/[0-9]+/)
      errors.add(:password, 'must contain at least one numeric digit')
    end

    include_special = Rails.application.credentials.backend.dig(:initialize, :security, :user_password,
                                                                :include_special)
    if include_special && !password.match(/[!@_#%&\-\$\^\*]+/)
      errors.add(:password, 'must contain at least one special character')
    end
  end

  def pick_timezone
    if tzinfo.to_s.strip.present? && manually_set_timezone.blank?
      update(manually_set_timezone: User.available_timezones.detect do |tz|
        tz.formatted_offset == tzinfo
      end.try(:tzinfo).try(:name))
    end
  end
end
