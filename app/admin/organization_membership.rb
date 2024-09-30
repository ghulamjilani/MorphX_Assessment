# frozen_string_literal: true

ActiveAdmin.register OrganizationMembership do
  menu parent: 'User'

  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :organization_id, label: 'Organization ID'
  filter :organization_name_cont, label: 'Organization name'
  filter :status, as: :select, collection: proc { OrganizationMembership::Statuses::ALL }
  filter :role, as: :select, collection: proc { OrganizationMembership::Roles::ALL }
  filter :membership_type, as: :select, collection: proc { OrganizationMembership.membership_types }
  filter :is_admin
  filter :created_at

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
