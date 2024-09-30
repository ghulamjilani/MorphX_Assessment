# frozen_string_literal: true

ActiveAdmin.register WishlistItem do
  menu parent: 'System'

  filter :model_id, label: 'Model ID'
  filter :model_type
  filter :user_id, label: 'User ID'

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
