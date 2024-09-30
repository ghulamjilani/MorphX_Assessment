# frozen_string_literal: true
class ChannelInvitedPresentership < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActsAsInvitableAbstractSessionPerson
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :channel
  belongs_to :presenter, touch: true

  validates :presenter_id, :channel_id, presence: true
  validates :presenter_id, uniqueness: { scope: :channel_id, message: 'has already been invited' }
  validate :not_organizer, if: :channel, on: :create

  after_create do
    if channel.approved?
      Rails.cache.delete("pending_user_invites/#{presenter.user.cache_key}")
      send_invite!
    end
  end
  after_create :send_firebase_notice
  after_update :notify_organizer_about_accepted_invitation, if: :invitation_just_got_accepted?
  after_update :notify_organizer_about_rejected_invitation, if: :invitation_just_got_rejected?
  after_destroy :delete_related_records

  def user
    @user ||= presenter.user
  end

  def user_id
    @user_id ||= presenter.user_id
  end

  def model
    channel
  end

  def email
    user.try(:email)
  end

  def room_member_role
    RoomMember::Kinds::PRESENTER
  end

  def send_invite!
    if invitation_sent_at.blank? || status != Statuses::PENDING
      ChannelMailer.presenter_invited(channel_id, presenter_id).deliver_later
      touch(:invitation_sent_at)

      user&.notify_about_invitation
    end
    user&.touch(:updated_at)
  end

  private

  def invitation_just_got_accepted?
    saved_change_to_status? && status_change == [ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING,
                                                 ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED]
  end

  def not_organizer
    if channel.organizer == user
      errors.add(:base, 'Organizer could not be invited as co-presenter')
    end
  end

  # fix https://lcmsportal.plan.io/issues/2742 but need to find the way to handle it correctly
  def delete_related_records
    return unless channel # https://immerss.airbrake.io/projects/135202/groups/1972084628479157692

    ChannelMailer.presenter_rejected(channel_id, presenter_id).deliver_later
    channel.sessions.where(presenter_id: presenter_id)
           .update_all(presenter_id: channel.available_presenter_ids.first, private: true)
  end

  def notify_organizer_about_accepted_invitation
    Immerss::ChannelMultiFormatMailer.new.user_accepted_your_channel_invitation(channel_id, presenter.user_id).deliver
  end

  def notify_organizer_about_rejected_invitation
    Immerss::ChannelMultiFormatMailer.new.user_rejected_your_channel_invitation(channel_id, presenter.user_id).deliver
  end
end
