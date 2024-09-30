# frozen_string_literal: true

module Api
  module V1
    module User
      class OrganizationMembershipsController < Api::V1::User::ApplicationController
        before_action :organization_membership, only: [:show]

        def index
          query = OrganizationMembership.where(user: current_user)
          query = query.where(organization_id: params[:organization_id]) if params[:organization_id].present?
          query = query.where(status: params[:status]) if params[:status].present?
          @count = query.count

          order_by = %w[id created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
          @organization_memberships = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
          @organizations = ::Organization.where(id: @organization_memberships.pluck(:organization_id))
        end

        def show
          authorize!(:read, organization_membership)
        end

        def update
          authorize!(:read, organization_membership)

          if (params[:status] == 'pending' && @organization_membership.status == 'cancelled') ||
             (params[:status] == 'active' && @organization_membership.status == 'suspended')
            group_ids = @organization_membership.group_ids
            valid_ids = valid_group_ids(group_ids)

            if valid_ids.empty? || valid_ids.count < group_ids.count
              return render_json(422, I18n.t('controllers.api.v1.user.access_management.organization_memberships.errors.invite_error'))
            end
          end

          if update_organization_membership_params.present?
            organization_membership.update(update_organization_membership_params)
          end
          @organization_membership.reload
          render :show
        end

        private

        def current_ability
          @current_ability ||= ::AbilityLib::OrganizationMembershipAbility.new(current_user).tap do |ability|
            ability.merge(::AbilityLib::OrganizationAbility.new(current_user))
            ability.merge(::AbilityLib::AccessManagement::GroupAbility.new(current_user))
          end
        end

        def organization_membership
          @organization_membership ||= OrganizationMembership.find(params.require(:id))
        end

        def update_organization_membership_params
          @update_params ||= if organization_membership.user == current_user
                               params.permit(:status).tap do |attributes|
                                 unless !Rails.application.credentials.global[:enterprise] && ( # invited users cannot reject or accept invites on enterprise
                                     (organization_membership.status == ::OrganizationMembership::Statuses::PENDING && attributes[:status] == OrganizationMembership::Statuses::ACTIVE) ||
                                     (organization_membership.status == ::OrganizationMembership::Statuses::ACTIVE && attributes[:status] == OrganizationMembership::Statuses::CANCELLED)
                                   )
                                   raise(AccessForbiddenError, I18n.t('controllers.api.v1.user.organization_memberships.errors.cannot_update_own_membership'))
                                 end
                               end
                             elsif organization_membership.participant? && current_ability.can?(:manage_team, organization_membership.organization)
                               params.permit(:status)
                             else
                               raise(AccessForbiddenError, I18n.t('controllers.api.v1.user.organization_memberships.errors.update_forbidden'))
                             end
        end

        def valid_group_ids(ids)
          groups = ::AccessManagement::Group.for_organization(current_user.current_organization).where(
            deleted: false, id: ids
          )
          # Validate group add permissions

          groups.select { |group| current_ability.can?(:add_role, group, @organization_membership) }.map(&:id)
        end
      end
    end
  end
end
