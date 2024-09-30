# frozen_string_literal: true
class Room < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions
  include ModelConcerns::Room::InteractiveService

  IMMERSIVE_CHANNEL_PREFIX    = 'presence-immersive-room-'
  SOURCE_CHANNEL_PREFIX       = 'presence-source-room-'
  LIVESTREAM_CHANNEL_PREFIX   = 'private-livestream-room-'
  PUBLIC_LIVESTREAM_CHANNEL_PREFIX = 'public-livestream-room-'

  module Statuses
    ACTIVE    = 'active'
    CLOSED    = 'closed'
    AWAITING  = 'awaiting'
    CANCELLED = 'cancelled'

    ALL = [ACTIVE, CLOSED, AWAITING, CANCELLED].freeze
  end
  Statuses::ALL.each do |const|
    define_method("#{const}?") { status == const }
  end

  module ServiceTypes
    RTMP   = 'rtmp'
    MOBILE = 'mobile'
    IPCAM  = 'ipcam'
    ZOOM   = 'zoom'
    webrtcservice = 'webrtcservice'
    WEBRTC = 'webrtc'

    ffmpegservice = [RTMP, MOBILE, IPCAM, WEBRTC].freeze
    INTERACTIVE = [ZOOM, webrtcservice].freeze
    ALL = [RTMP, MOBILE, IPCAM, ZOOM, webrtcservice, WEBRTC].freeze
  end
  ServiceTypes::ALL.each do |const|
    define_method("#{const}?") { service_type == const }
  end

  module RecorderTypes
    NONE                  = nil
    RECORD                = 'record'
    LIVESTREAM            = 'livestream'
    RECORD_AND_LIVESTREAM = 'record_and_livestream'
    RTMP_STREAM           = 'rtmp_stream'

    ALL = [NONE,
           RECORD,
           LIVESTREAM,
           RECORD_AND_LIVESTREAM,
           RTMP_STREAM].freeze
    ALL.each do |const|
      ::Room.send(:define_method, "recorder_#{const || 'empty'}?", -> { recorder_type == const })
    end
  end

  scope :active, -> { where(status: Statuses::ACTIVE) }
  scope :awaiting, -> { where(status: Statuses::AWAITING) }
  scope :closed, -> { where(status: Statuses::CLOSED) }
  scope :cancelled, -> { where(status: Statuses::CANCELLED) }

  scope :not_active, -> { where.not(status: Statuses::ACTIVE) }
  scope :not_awaiting, -> { where.not(status: Statuses::AWAITING) }
  scope :not_closed, -> { where.not(status: Statuses::CLOSED) }
  scope :not_cancelled, -> { where.not(status: Statuses::CANCELLED) }

  scope :upcoming, -> { where('now() < actual_end_at') }

  scope :with_open_lobby, lambda {
    where(':time_now BETWEEN actual_start_at::timestamp AND actual_end_at::timestamp', { time_now: Time.zone.now })
  }

  scope :current_rooms, lambda {
    where(":time_now BETWEEN actual_start_at::timestamp AND actual_end_at::timestamp + (INTERVAL '1 minute' * 15)", { time_now: Time.now.utc })
  }

  scope :ffmpegservice, -> { where(service_type: ServiceTypes::ffmpegservice) }

  belongs_to :abstract_session, polymorphic: true, touch: true
  belongs_to :session, foreign_key: 'abstract_session_id', class_name: 'Session'
  belongs_to :presenter_user, class_name: 'User'

  has_many :room_members, dependent: :delete_all
  has_many :room_members_pinned, -> { where(pinned: true) }, class_name: 'RoomMember'
  has_many :interactive_access_tokens, through: :session
  has_many :videos
  has_many :transcoder_uptimes, as: :streamable, dependent: :destroy

  validates :actual_start_at, :actual_end_at, :abstract_session_type, presence: true
  validates :status, presence: true, inclusion: { in: Statuses::ALL }
  validates :service_type, presence: true, inclusion: { in: ServiceTypes::ALL }

  validate :time_overlap

  after_destroy do
    SidekiqSystem::Schedule.remove(ApiJobs::StopSession, id)
    SidekiqSystem::Schedule.remove(ApiJobs::AutoStartSession, id)
    SidekiqSystem::Schedule.remove(ApiJobs::StartFfmpegserviceStream, id) if ffmpegservice?
  end

  after_commit :perform_schedule, on: %i[create update]
  after_commit :create_presenter_room_member, on: [:create]
  after_commit :update_presenter_room_member, if: :saved_change_to_presenter_user_id?
  after_commit :create_interactive_access_tokens, on: [:create]
  after_commit :cable_status_notifications, if: :saved_change_to_status?
  after_commit :cable_screen_share_notification, if: :saved_change_to_is_screen_share_available?

  accepts_nested_attributes_for :room_members
  accepts_nested_attributes_for :session, allow_destroy: false

  def active!
    update(status: Statuses::ACTIVE)
    touch(:became_active_at) if became_active_at.nil?
  end

  def awaiting!
    update(status: Statuses::AWAITING)
  end

  def closed!
    update(status: Statuses::CLOSED, actual_end_at: Time.now.utc)
    abstract_session.stop!
    if Rails.env.production? && (abstract_session.stopped_at > (abstract_session.end_at + 10.minutes))
      Airbrake.notify(RuntimeError.new('Room has wrong stopped_at time'),
                      parameters: {
                        abstract_session_id: abstract_session.id,
                        room_id: id,
                        end_at: abstract_session.end_at,
                        stopped_at: abstract_session.stopped_at
                      })
    end
  end

  def start_record!
    update_attribute(:recording, true)
  end

  def resume_record!
    update_attribute(:recording, true)
  end

  def pause_record!
    update_attribute(:recording, false)
  end

  def stop_record!
    update_attribute(:recording, nil)
  end

  def mute!
    update_attribute(:mic_disabled, true)
  end

  def unmute!
    update_attribute(:mic_disabled, false)
  end

  def video_disable!
    update_attribute(:video_disabled, true)
  end

  def video_enable!
    update_attribute(:video_disabled, false)
  end

  def backstage_disable!
    update_attribute(:backstage, false)
  end

  def backstage_enable!
    update_attribute(:backstage, true)
  end

  def immersive_channel
    "#{IMMERSIVE_CHANNEL_PREFIX}#{id}"
  end

  def livestream_channel
    "#{LIVESTREAM_CHANNEL_PREFIX}#{id}"
  end

  def public_livestream_channel
    "#{PUBLIC_LIVESTREAM_CHANNEL_PREFIX}#{id}"
  end

  def source_channel
    "#{SOURCE_CHANNEL_PREFIX}#{id}"
  end

  def cable_immersive_channel
    'PresenceImmersiveRoomsChannel'
  end

  def cable_livestream_channel
    'PrivateLivestreamRoomsChannel'
  end

  def cable_public_livestream_channel
    'PublicLivestreamRoomsChannel'
  end

  def cable_source_channel
    'PresenceSourceRoomsChannel'
  end

  def stream_m3u8_url
    ffmpegservice_account.stream_m3u8_url
  rescue StandardError
    ''
  end

  def vidyoio_token
    Vidyo::Token.new(key: ENV['VIDYOIO_KEY'], application_id: ENV['VIDYOIO_APPID'], user_name: presenter_user_id.to_s,
                     expires_in: 3600).serialize
  end

  def ffmpegservice_account
    abstract_session.ffmpegservice_account
  end

  def self.assign_room(session)
    start_room = if session.is_a?(Session)
                   session.start_at - session.pre_time.minutes
                 else
                   session.start_at
                 end

    reserved = session.room || session.build_room

    reserved.presenter_user = session.organizer
    reserved.status = Statuses::AWAITING if reserved.new_record?

    reserved.recorder_type = if session.do_record? && session.do_livestream?
                               RecorderTypes::RECORD_AND_LIVESTREAM
                             elsif session.do_record?
                               RecorderTypes::RECORD
                             elsif session.do_livestream?
                               RecorderTypes::LIVESTREAM
                             else
                               RecorderTypes::NONE
                             end
    reserved.service_type = case session.service_type
                            when 'rtmp'
                              'rtmp'
                            when 'zoom'
                              'zoom'
                            when 'ipcam'
                              'ipcam'
                            when 'webrtc'
                              'webrtc'
                            when 'mobile'
                              if session.immersive_delivery_method?
                                'webrtcservice'
                              else
                                'mobile'
                              end
                            else
                              'webrtcservice'
                            end

    reserved.actual_start_at = start_room
    reserved.actual_end_at = session.stopped_at || session.end_at
    reserved.updated_at = Time.now.utc
  end

  def recording_started?
    !recording.nil?
  end

  def recording_paused?
    recording == false
  end

  def recording_now?
    recording == true
  end

  def recorder_has_livestream?
    recorder_livestream? || recorder_record_and_livestream?
  end

  def i18n_type
    abstract_session_type.downcase.to_sym
  end

  def open?
    Time.zone.now > actual_start_at && Time.zone.now < actual_end_at # && !closed? && !cancelled?
  end

  def rtmp_or_cam?
    service_type == 'rtmp' || service_type == 'ipcam' || service_type == 'mobile'
  end

  def ffmpegservice?
    rtmp? || ipcam? || mobile? || webrtc?
  end

  def enable_list(list_id)
    list = session.organization.lists.find_by(id: list_id)
    return false unless list

    session.organization.lists.update_all(selected: false)
    # list.update_attributes(selected: true)
    abstract_session.list_ids = [list_id]

    PresenceImmersiveRoomsChannel.broadcast_to(self, { event: 'enable-list', data: { users: 'all', list_id: list_id } })
    PrivateLivestreamRoomsChannel.broadcast_to(self, { event: 'enable-list', data: { users: 'all', list_id: list_id } })
    PublicLivestreamRoomsChannel.broadcast_to(self, { event: 'enable-list', data: { users: 'all', list_id: list_id } })
    list
  end

  def disable_list
    session.organization.lists.update_all(selected: false)
    abstract_session.list_ids = []

    PresenceImmersiveRoomsChannel.broadcast_to(self, { event: 'disable-list', data: { users: 'all', list_id: 'all' } })
    PrivateLivestreamRoomsChannel.broadcast_to(self, { event: 'disable-list', data: { users: 'all', list_id: 'all' } })
    PublicLivestreamRoomsChannel.broadcast_to(self, { event: 'disable-list', data: { users: 'all', list_id: 'all' } })
  end

  def enable_chat
    abstract_session.update({ allow_chat: true })
  end

  def disable_chat
    abstract_session.update({ allow_chat: false })
  end

  def product_scanned(product, list)
    PresenceImmersiveRoomsChannel.broadcast_to(self,
                                               { event: 'product_scanned',
                                                 data: { users: 'all', product: product, list: list } })
    PrivateLivestreamRoomsChannel.broadcast_to(self,
                                               { event: 'product_scanned',
                                                 data: { users: 'all', product: product, list: list } })
    PublicLivestreamRoomsChannel.broadcast_to(self,
                                              { event: 'product_scanned',
                                                data: { users: 'all', product: product, list: list } })
  end

  def autostart
    abstract_session.reload.autostart
  end

  def role_for(user:)
    if presenter_user_id == user.id
      'presenter'
    elsif abstract_session.is_a?(Session)
      if SessionParticipation.exists?(session_id: abstract_session.id, participant_id: user.participant_id)
        'participant'
      elsif SessionCoPresentership.exists?(session_id: abstract_session.id, presenter_id: user.presenter_id)
        'co_presenter'
      elsif Livestreamer.exists?(session_id: abstract_session.id, participant_id: user.participant_id)
        'livestreamer'
      elsif (room_member = room_members.find_by(abstract_user: user))
        room_member.kind
      elsif user.service_admin? || user.platform_owner?
        user.create_participant! if user.participant.blank?
        abstract_session.session_participations.create!(participant: user.participant)
        'participant'
      end
    end
  end

  def cable_status_notifications
    if active?
      user_ids = room_members.for_users.where(backstage: false).audience.pluck(:abstract_user_id)
      SessionsChannel.broadcast 'session-started', { session_id: abstract_session.id }
      PresenceImmersiveRoomsChannel.broadcast_to self, event: 'room_active', data: {}
      PresenceImmersiveRoomsChannel.broadcast_to self, event: 'join', data: { users: user_ids }
    elsif closed?
      RoomsChannel.broadcast 'disable', { room_id: id }
      SessionsChannel.broadcast 'session-stopped', { session_id: abstract_session_id }
      PresenceImmersiveRoomsChannel.broadcast_to self, event: 'session-ended', data: {}
      PrivateLivestreamRoomsChannel.broadcast_to self, event: 'livestream-ended', data: {}
      PublicLivestreamRoomsChannel.broadcast_to self, event: 'livestream-ended', data: {}
    end
  end

  def cable_screen_share_notification
    message = { is_screen_share_available: is_screen_share_available }
    PresenceImmersiveRoomsChannel.broadcast_to(self, { event: 'screen-share-ability-changed', data: message })
    PrivateLivestreamRoomsChannel.broadcast_to(self, { event: 'screen-share-ability-changed', data: message })
  end

  def cable_pinned_notification
    pinned_members = room_members_pinned.pluck(:id)
    PresenceImmersiveRoomsChannel.broadcast_to(self,
                                               { event: 'pinned_users', data: { pinned_members: pinned_members } })
  end

  # def cable_record_notifications
  #   if recording
  #   elsif recording.nil?
  #   end
  # end

  def user_backstage_enabled?(user)
    return false unless user.is_a?(User)
    return true if user.id == presenter_user_id
    return false unless backstage?

    room_members.audience.exists?(abstract_user: user, backstage: true)
  end

  private

  def time_overlap
    return if Rails.env.test? && ENV['SKIP_OVERLAP_CHECK']
    return if abstract_session && (abstract_session.finished? || abstract_session.cancelled?)

    result = Room.where(presenter_user_id: presenter_user_id).where.not(status: 'closed')
                 .where(%{
        ("rooms"."actual_start_at", "rooms"."actual_end_at")
          OVERLAPS
        (:actual_start_at::timestamp, :actual_end_at::timestamp)
      }, { actual_start_at: actual_start_at, actual_end_at: actual_end_at })
    result = result.where.not(rooms: { id: id }) unless new_record?
    if result.exists?
      room = result.first
      overlapped = room.abstract_session
      start_time = room.actual_start_at.in_time_zone(presenter_user.timezone).strftime('%H:%M')
      end_time   = room.actual_end_at.in_time_zone(presenter_user.timezone).strftime('%H:%M')

      errors.add(:base, :time_overlap,
                 name: "#{overlapped.title} start time: #{start_time} - end time: #{end_time}",
                 link: overlapped.relative_path,
                 model: I18n.t("activerecord.models.#{overlapped.class.to_s.downcase}"))

    elsif (abstract_session = presenter_user.participate_between(actual_start_at, actual_end_at,
                                                                 %w[gt_presenter s_presenter]).first)
      message = I18n.t('activerecord.errors.messages.one_role_at_the_same_time',
                       name: abstract_session.title.to_s,
                       link: abstract_session.relative_path,
                       model: I18n.t("activerecord.models.#{abstract_session.class.to_s.downcase}")).html_safe
      errors.add(:base, message)
    end
  end

  def perform_schedule
    SidekiqSystem::Schedule.remove(SessionJobs::PingLivestream, id)
    if zoom? && !SidekiqSystem::Schedule.exists?(SessionJobs::PingLivestream, id)
      SessionJobs::PingLivestream.perform_at(abstract_session.reload.start_at + 10.seconds, id)
    end

    if @_new_record_before_last_commit || previous_changes[:actual_start_at].present? || previous_changes[:actual_end_at].present? || previous_changes[:service_type].present?
      as = abstract_session.reload

      # don't run jobs for zoom sessions
      if autostart && !zoom? && (@_new_record_before_last_commit || previous_changes[:actual_start_at].present?)
        SidekiqSystem::Schedule.remove(ApiJobs::AutoStartSession, id)
        ApiJobs::AutoStartSession.perform_at(as.reload.start_at, id)
      end

      if ffmpegservice?
        SidekiqSystem::Schedule.remove(ApiJobs::StartFfmpegserviceStream, id)
        ApiJobs::StartFfmpegserviceStream.perform_at(actual_start_at + 5.seconds, id)
      end

      SidekiqSystem::Schedule.remove(ApiJobs::StopSession, id)
      ApiJobs::StopSession.perform_at(actual_end_at - 5.seconds, id) unless zoom?

      message = {
        start_at: actual_start_at,
        end_at: actual_end_at,
        end_at_i: actual_end_at.to_i,
        time_left: actual_end_at - Time.now,
        server_time: Time.now.utc.to_i * 1000,
        session_start_at: as.start_at
      }

      PresenceImmersiveRoomsChannel.broadcast_to(self, { event: 'room_updated', data: message })
      PrivateLivestreamRoomsChannel.broadcast_to(self, { event: 'room_updated', data: message })
      PublicLivestreamRoomsChannel.broadcast_to(self, { event: 'room_updated', data: message })
    elsif saved_change_to_status? && closed?
      SidekiqSystem::Schedule.remove(ApiJobs::StopSession, id)
      session.remove_stop_no_stream_job
    end
  end

  def create_presenter_room_member
    return unless persisted?

    room_members.find_or_create_by(abstract_user_id: presenter_user_id, kind: 'presenter')
  end

  def update_presenter_room_member
    return unless persisted?

    room_members.find_by(kind: 'presenter')&.destroy
    room_members.find_or_create_by(abstract_user_id: presenter_user_id, kind: 'presenter')
  end

  def create_interactive_access_tokens
    return if session.blank?

    if session.interactive_guests
      session.interactive_access_tokens.find_or_create_by(individual: false, guests: false)
      session.interactive_access_tokens.find_or_create_by(individual: false, guests: true)
    end
  end
end
