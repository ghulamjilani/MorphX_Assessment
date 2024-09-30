# frozen_string_literal: true

class InteractiveAccessTokenPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none if user.blank?

      scope
        .joins(session: { channel: :organization })
        .joins(%(LEFT JOIN channel_invited_presenterships ON channel_invited_presenterships.channel_id = channels.id))
        .joins(%(LEFT JOIN organization_memberships ON organization_memberships.organization_id = organizations.id))
        .where(%{
               sessions.presenter_id=:presenter_id
               OR organizations.user_id=:user_id
               OR (channel_invited_presenterships.presenter_id=:presenter_id AND channel_invited_presenterships.status=:presentership_status_accepted)
               OR (organization_memberships.user_id=:user_id AND organization_memberships.role=:membership_role_admin)
             },
               user_id: user.id,
               presenter_id: user.presenter&.id,
               presentership_status_accepted: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED,
               membership_role_admin: OrganizationMembership::Roles::ADMINISTRATOR)
        .distinct
    end
  end

  def show?
    return false if user.blank?

    session = record.session
    channel = session.channel
    organization = channel.organization

    return true if user == organization.user

    return true if organization.organization_memberships_active.exists?(user_id: user.id,
                                                                        role: OrganizationMembership::Roles::ADMINISTRATOR)

    return false if user.presenter.blank?

    return true if channel.channel_invited_presenterships.exists?(presenter_id: user.presenter_id,
                                                                  status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED)

    return true if session.session_co_presenterships.exists?(presenter_id: user.presenter_id)

    user.presenter == session.presenter
  end

  def create?
    show?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
