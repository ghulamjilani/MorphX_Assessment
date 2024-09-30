# frozen_string_literal: true

ActiveAdmin.register Poll::Poll, as: 'Poll' do
  menu parent: 'Polls'

  actions :all, except: :destroy

  filter :poll_template_id, label: 'Template ID'
  filter :question
  filter :model_type, as: :select, collection: %w[Channel Session Recording Video]
  filter :model_id, label: 'Model ID'
  filter :created_at
  filter :updated_at

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
