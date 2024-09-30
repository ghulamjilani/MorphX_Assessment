# frozen_string_literal: true

module Api
  module V1
    module User
      module AccessManagement
        class GroupMembersController < Api::V1::User::AccessManagement::ApplicationController
          before_action :set_organization

          def show
            @group_member = @organization.all_groups_members.find(params[:id])
          end

          def update
            authorize!(:invite_members, @organization)
            @group_member = @organization.all_groups_members.find(params[:id])
            channel_ids = params[:channel_ids].is_a?(Array) ? params[:channel_ids] : params[:channel_ids].to_s.split(',')
            channel_ids = @organization.channels.where(id: channel_ids).pluck(:id)
            @group_member.channel_ids = channel_ids
            render :show
          end

          private

          def set_organization
            @organization = ::Organization.joins(%(LEFT JOIN organization_memberships ON organization_memberships.organization_id = organizations.id))
                                          .where('organizations.user_id = :id OR organization_memberships.user_id = :id', id: current_user.id).find(params[:organization_id])
          end
        end
      end
    end
  end
end
