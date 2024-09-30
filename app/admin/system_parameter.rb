# frozen_string_literal: true

ActiveAdmin.register SystemParameter do
  menu parent: 'Admin settings'
  before_action do
    SystemParameter.class_eval do
      def to_param
        id.to_s
      end
    end
  end
  actions :all
  form do |f|
    f.inputs do
      f.input :key
      f.input :value
      f.input :description
    end
    f.actions
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
