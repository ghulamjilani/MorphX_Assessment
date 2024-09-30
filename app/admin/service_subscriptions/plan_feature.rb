# frozen_string_literal: true

ActiveAdmin.register PlanFeature do
  menu parent: I18n.t('activeadmin.stripe_db.menu')
  actions :all
  action_item :seed, only: :index do
    link_to('Seed Plan Features', seed_service_admin_panel_plan_features_path, method: :post)
  end

  collection_action :seed, method: :post do
    load Rails.root.join('db/seeds/plan_features.rb')

    redirect_to collection_path, alert: 'Plan Features updated'
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
