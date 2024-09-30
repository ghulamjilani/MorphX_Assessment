# frozen_string_literal: true

ActiveAdmin.register Shop::ListsProduct, as: 'ListsProduct' do
  menu parent: 'Shop'
  actions :all

  filter :list_id, label: 'List ID'
  filter :list_name_cont, label: 'List Name'
  filter :product_id, label: 'Product ID'
  filter :product_title_cont, label: 'Product Name'

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
