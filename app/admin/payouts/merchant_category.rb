# frozen_string_literal: true

ActiveAdmin.register MerchantCategory do
  menu parent: 'Payouts'

  actions :all

  action_item :seed, only: :index do
    link_to('Seed MCC', seed_service_admin_panel_merchant_categories_path, method: :post)
  end

  collection_action :seed, method: :post do
    load Rails.root.join(Rails.root, 'db', 'seeds', 'mcc.rb')

    redirect_to collection_path, alert: 'MCC updated'
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
