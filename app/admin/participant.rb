# frozen_string_literal: true

ActiveAdmin.register Participant do
  menu parent: 'User'

  actions :all, except: :destroy

  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'

  csv do
    column :id
    column(:user_id_) { |o| o.user.id }
    column(:user_name) { |o| o.user.public_display_name }
    column(:user_email) { |o| o.user.email }
    column :created_at
    column :updated_at
  end

  index do
    selectable_column
    column :id
    column :user
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :user_id, label: 'User ID'
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
