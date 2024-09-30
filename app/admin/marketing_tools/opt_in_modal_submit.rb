# frozen_string_literal: true

ActiveAdmin.register MarketingTools::OptInModalSubmit, as: 'Opt-in Modal Submits' do
  menu parent: 'Marketing Tools'

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
