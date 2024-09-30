# frozen_string_literal: true

ActiveAdmin.register AccessManagement::GroupsMember do
  menu parent: 'Access Management'

  actions :all

  filter :is_channel
  filter :access_management_group_id
  filter :organization_membership_id
  filter :user_id
  filter :group_id

  form do |f|
    f.inputs do
      f.input :is_channel
      f.input :organization_membership, as: :select, collection: OrganizationMembership.all.map { |m|
        ["#{m.organization.name} (#{m.user.email})", m.id]
      }
      f.input :group, as: :select
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
