# frozen_string_literal: true

ActiveAdmin.register AccessManagement::Credential do
  menu parent: 'Access Management'

  actions :all
  action_item :seed, only: :index do
    link_to('Seed credentials', seed_service_admin_panel_access_management_credentials_path, method: :post)
  end

  collection_action :seed, method: :post do
    load File.join(Rails.root, 'db', 'seeds', 'credentials.rb')

    redirect_to collection_path, alert: 'Credentials updated'
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
