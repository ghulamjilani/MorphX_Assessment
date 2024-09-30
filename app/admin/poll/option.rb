# frozen_string_literal: true

ActiveAdmin.register Poll::Option, as: 'Poll Option' do
  menu parent: 'Polls'

  actions :all, except: :destroy

  filter :poll_id, label: 'Poll ID'
  filter :title
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
