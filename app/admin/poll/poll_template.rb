# frozen_string_literal: true

ActiveAdmin.register Poll::Template::Poll, as: 'PollTemplate' do
  menu parent: 'Polls'

  actions :all, except: :destroy

  filter :organization_id, label: 'Organization ID'
  filter :user_id, label: 'User ID'
  filter :name
  filter :question
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
