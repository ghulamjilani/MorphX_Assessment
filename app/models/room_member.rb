# frozen_string_literal: true
class RoomMember < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  module AbstractUserTypes
    GUEST = 'Guest'
    USER = 'User'

    ALL = [GUEST, USER].freeze
  end

  belongs_to :room
  belongs_to :abstract_user, polymorphic: true

  belongs_to :ban_reason
  has_one :session, through: :room, source: :abstract_session, source_type: 'Session', class_name: 'Session'

  delegate :cable_pinned_notification, to: :room

  validates! :kind, :room, :display_name, presence: true
  validates! :abstract_user, presence: true
  validates :ban_reason, presence: true, if: :banned?
  # validates :user_id  , uniqueness: { scope: :room_id }, if: Proc.new { |obj| !%w(source presenter).include?(obj.kind) }
  validates :source_id, presence: true, if: proc { |obj| obj.kind == 'source' }

  before_validation :set_display_name

  before_create :set_mic_and_video

  after_commit :cable_pinned_notification, if: :saved_change_to_pinned?
  after_commit :notify_about_ban, if: :saved_change_to_banned?
  after_commit :remove_session_participation, if: :saved_change_to_banned?
  after_commit { abstract_user&.touch if abstract_user&.persisted? }

  module Kinds
    PRESENTER    = 'presenter'
    CO_PRESENTER = 'co_presenter'
    PARTICIPANT  = 'participant'
    LIVESTREAMER = 'livestream'
    SOURCE = 'source'

    ALL = [
      PRESENTER,
      CO_PRESENTER,
      PARTICIPANT,
      LIVESTREAMER,
      SOURCE
    ].freeze
  end

  scope :presenters,                  -> { where(kind: Kinds::PRESENTER) }
  scope :co_presenters,               -> { where(kind: Kinds::CO_PRESENTER) }
  scope :participants,                -> { where(kind: Kinds::PARTICIPANT) }
  scope :audience,                    -> { where(kind: [Kinds::CO_PRESENTER, Kinds::PARTICIPANT]) }
  scope :audience_with_source,        -> { where(kind: [Kinds::CO_PRESENTER, Kinds::PARTICIPANT, Kinds::SOURCE]) }
  scope :co_presenters_participants,  lambda {
                                        select(%i[abstract_user_id mic_disabled video_disabled has_control backstage]).where(kind: [RoomMember::Kinds::CO_PRESENTER, RoomMember::Kinds::PARTICIPANT])
                                      }
  scope :livestreams,                 -> { where(kind: 'livestream') }
  scope :banned,                      -> { where(banned: true) }
  scope :not_banned,                  -> { where.not(banned: true) }
  scope :for_guests,                      -> { where(abstract_user_type: 'Guest') }
  scope :for_users,                       -> { where(abstract_user_type: 'User') }

  AbstractUserTypes::ALL.each do |abstract_type|
    # 'guest', 'user'
    define_method abstract_type.parameterize.underscore do
      return nil unless abstract_user_type.eql?(abstract_type)

      abstract_user
    end

    # 'guest?', 'user?'
    define_method "#{abstract_type.parameterize.underscore}?" do
      abstract_user_type.eql?(abstract_type)
    end
  end

  # NOTE: used in SessionAccounting
  def presenter_id
    raise ArgumentError unless kind == Kinds::CO_PRESENTER && !guest?
    raise ArgumentError if guest?

    User.find(abstract_user_id).presenter_id
  end

  def allow_control!
    update(has_control: true)
  end

  def disable_control!
    update(has_control: false)
  end

  def mute!
    update(mic_disabled: true)
  end

  def unmute!
    update(mic_disabled: false)
  end

  def video_disable!
    update(video_disabled: true)
  end

  def video_enable!
    update(video_disabled: false)
  end

  def backstage_disable!
    update(backstage: false)
  end

  def backstage_enable!
    update(backstage: true)
  end

  def joined!
    update(joined: true)
  end

  def pinned!
    update(pinned: true)
  end

  def unpinned!
    update(pinned: false)
  end

  def notify_about_ban
    # return if guest?
    return if !banned && @_new_record_before_last_commit

    if banned
      PresenceImmersiveRoomsChannel.broadcast_to room, event: 'ban-kick',
                                                       data: { room_member_id: id, ban_reason: ban_reason&.name }
      Mailer.ban_user(id).deliver_later if abstract_user.present? && user?
    else
      PresenceImmersiveRoomsChannel.broadcast_to room, event: 'unban', data: { room_member_id: id }
      Mailer.unban_user(id).deliver_later if abstract_user.present? && user?
    end
  end

  def remove_session_participation
    return unless banned
    return unless user
    return if user.participant.blank?

    session.session_participations.where(participant: user.participant).find_each(&:destroy)
  end

  def jwt_secret
    Digest::MD5.hexdigest(token + Rails.application.secret_key_base)
  end

  private

  def set_mic_and_video
    if kind != 'presenter'
      self.mic_disabled   = room.mic_disabled
      self.video_disabled = room.video_disabled
      self.backstage      = room.backstage
    end
    true
  end

  def set_display_name
    self.display_name = abstract_user.public_display_name
  end
end
