# frozen_string_literal: true

ActiveAdmin.register PayoutMethod do
  menu parent: 'Payouts'

  actions :all
  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :pid, label: 'Account Stripe ID'

  index do
    selectable_column
    id_column
    column :user
    column :connect_account
    column :status
    column :pid
    column :country
    column :is_default
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :user
      row :connect_account
      row :business_type
      row :provider
      row :details
      row :status
      row :pid
      row :country
      row :is_default
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :user_id
      f.input :pid
      f.input :business_type
      f.input :provider
      f.input :details
      f.input :status
      f.input :country
      f.input :is_default
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
