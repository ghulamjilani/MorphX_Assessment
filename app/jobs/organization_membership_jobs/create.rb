# frozen_string_literal: true

class OrganizationMembershipJobs::Create < ApplicationJob
  def perform(params)
    params.symbolize_keys!
    organization = ::Organization.find(params[:organization_id])
    user = ::User.find(params[:user_id])
    invited_user = ::User.find_by(email: params[:email].to_s.strip.downcase) if params[:email]
    if Rails.application.credentials.backend.dig(:organization_membership, :delete) && %w[t T].include?(params[:delete])
      organization.organization_memberships.find_by(user_id: invited_user.id)&.destroy if invited_user
      return
    end
    if invited_user.blank?
      gender = case params[:gender]
               when 'M', 'm'
                 ::User::Genders::MALE
               when 'F', 'f'
                 ::User::Genders::FEMALE
               when 'P', 'p'
                 ::User::Genders::HIDDEN
               end

      birthday = begin
        DateTime.parse(params[:birthday])
      rescue StandardError
        nil
      end

      invited_user = ::User.invite!(
        { email: params[:email], first_name: params[:first_name], last_name: params[:last_name], gender: gender, birthdate: birthday }, user
      ) do |u|
        u.before_create_generic_callbacks_and_skip_validation
        u.skip_invitation = true
      end
    end
    organization_membership = organization.organization_memberships.find_or_create_by(user_id: invited_user.id)
    status = Rails.application.credentials.global[:enterprise] ? ::OrganizationMembership::Statuses::ACTIVE : ::OrganizationMembership::Statuses::PENDING
    organization_membership.update(membership_type: :participant, status: status) if organization_membership.status != 'active'

    member_group = ::AccessManagement::Group.find_by(code: :member, enabled: true)
    params[:group_ids] << { group_id: member_group.id, channel_ids: [] } if member_group

    ability = ::AbilityLib::AccessManagement::GroupAbility.new(user)
    params[:group_ids].each do |group|
      group.symbolize_keys!
      available_group = ::AccessManagement::Group.for_organization(organization).where(deleted: false, id: group[:group_id]).first
      # Validate group add permissions
      group_id = available_group.id if ability.can?(:add_role, available_group, organization_membership)
      next unless group_id

      group_member = organization_membership.groups_members.create(access_management_group_id: group_id)
      channels = organization.channels.where(id: group[:channel_ids].to_a)
      group_member.channels << channels unless channels.empty?
    end
    invited_user.create_presenter if invited_user.presenter.blank?
  end
end
