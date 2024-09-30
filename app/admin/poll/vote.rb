# frozen_string_literal: true

ActiveAdmin.register Poll::Vote, as: 'Poll Vote' do
  menu parent: 'Polls'

  actions :all, except: :destroy

  filter :user_id, label: 'User ID'
  filter :option_id, label: 'Option ID'
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
