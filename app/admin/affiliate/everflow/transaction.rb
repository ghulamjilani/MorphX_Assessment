# frozen_string_literal: true

ActiveAdmin.register Affiliate::Everflow::Transaction do
  menu parent: 'Everflow Affiliate'

  actions :all

  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :transaction_id, label: 'Transaction ID'
  filter :created_at

  index do
    selectable_column
    column :id
    column :user
    column('Transaction ID', &:transaction_id)
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.inputs do
      f.input :user_id, label: 'User ID'
      f.input :transaction_id, label: 'Transaction ID'
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
