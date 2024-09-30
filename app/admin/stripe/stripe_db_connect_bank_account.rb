# frozen_string_literal: true

ActiveAdmin.register StripeDb::ConnectBankAccount, as: 'Connect Bank Accounts' do
  menu parent: 'Payouts'

  actions :all

  filter :stripe_account_id, label: 'Account Stripe ID'
  filter :stripe_id, label: 'Bank Account Stripe ID'
  filter :account_holder_name
  filter :account_holder_type
  filter :last4
  filter :bank_name
  filter :country, as: :select, collection: proc { ::Payouts::Countries::ALL.map { |h| [h.last, h.first] } }
  filter :currency
  filter :default_for_currency
  filter :status
  filter :created_at

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
