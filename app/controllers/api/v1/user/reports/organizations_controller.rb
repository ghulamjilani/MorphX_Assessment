# frozen_string_literal: true

module Api
  module V1
    module User
      module Reports
        class OrganizationsController < Api::V1::User::ApplicationController
          def index
            render_json(404, 'No organization found') and return if !current_user.platform_owner? && current_user.current_organization.blank?
            render_json(403, 'Access Denied') and return if !current_user.platform_owner? && cannot?(:view_revenue_report, current_user.current_organization)

            query = if current_user.platform_owner?
                      ::Organization.where(id: ::Reports::V1::RevenuePurchasedItem.organization_ids)
                    elsif current_user.has_organization_credential?(current_user.current_organization, :view_revenue_report)
                      ::Organization.where(id: current_user.current_organization_id)
                    else
                      ::Organization.none
                    end

            query = query.where('organizations.name ILIKE ?', "%#{params[:name]}%") if params[:name].present?
            @count = query.count
            @organizations = query.order(name: :asc).limit(@limit).offset(@offset)
          end
        end
      end
    end
  end
end
