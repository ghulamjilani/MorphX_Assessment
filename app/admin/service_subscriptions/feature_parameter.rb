# frozen_string_literal: true

ActiveAdmin.register FeatureParameter do
  menu parent: I18n.t('activeadmin.stripe_db.menu')
  actions :all

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
