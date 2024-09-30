# frozen_string_literal: true

ActiveAdmin.register Shop::AttachedList, as: 'AttachedList' do
  menu parent: 'Shop'
  actions :all

  filter :model_type, as: :select, collection: proc { Shop::AttachedList::MODEL_TYPES }
  filter :list_id, label: 'List ID'
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
