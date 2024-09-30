# frozen_string_literal: true

ActiveAdmin.register FeatureUsage do
  menu parent: I18n.t('activeadmin.stripe_db.menu')
  actions :all

  filter :id
  filter :plan_feature
  filter :plan_feature_id, label: 'PlanFeature Id'
  filter :organization
  filter :organization_id, label: 'Organization Id'
  filter :fact_usage_bytes

  index do
    selectable_column
    column :id
    column :plan_feature
    column :plan_feature_id
    column :organization
    column :organization_id
    column :allocated_usage_bytes
    column :fact_usage_bytes
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
