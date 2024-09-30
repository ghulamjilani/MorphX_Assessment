# frozen_string_literal: true
# TODO: I'm not sure that we need this model for channel presenterships
# in case if we have role 'presenter' in OrganizationMembership
# and in this case we can use ChannelInvitedPresentership that contains co-presenter info.
class OrganizationalChannelPresentership < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :channel
  belongs_to :presenter

  validate :not_organization_owner, if: :channel, on: :create

  validates :presenter, uniqueness: { scope: [:channel], if: :channel }

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

  private

  def not_organization_owner
    if channel.presenter_id && (channel.organizer.presenter_id == presenter_id)
      errors.add(:base, 'organizer could not be added as channel presenter')
    end
  end
end
