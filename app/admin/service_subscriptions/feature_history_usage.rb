# frozen_string_literal: true

ActiveAdmin.register FeatureHistoryUsage do
  menu parent: I18n.t('activeadmin.stripe_db.menu')
  actions :all

  filter :id
  filter :model_type
  filter :model_id, label: 'Model Id'
  filter :action_name
  filter :feature_usage_id, label: 'FeatureUsage Id'
  filter :usage_bytes

  index do
    selectable_column
    column :id
    column :feature_usage
    column :feature_usage_id
    column :model
    column :model_type
    column :model_id
    column :usage_bytes
    column :created_at
    column :updated_at

    actions
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
