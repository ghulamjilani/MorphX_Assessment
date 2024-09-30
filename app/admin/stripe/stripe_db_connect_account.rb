# frozen_string_literal: true

ActiveAdmin.register StripeDb::ConnectAccount, as: 'Connect Accounts' do
  menu parent: 'Payouts'

  actions :all

  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :account_id, label: 'Stripe Account ID'

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
