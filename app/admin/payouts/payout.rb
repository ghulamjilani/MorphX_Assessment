# frozen_string_literal: true

ActiveAdmin.register Payout do
  menu parent: 'Payouts'

  actions :all

  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :status, as: :select, collection: [['Pending', 0], ['Paid', 1], ['Failed', 2]]
  filter :created_at

  member_action :pay, method: :post do
    redirect_to resource_path, notice: 'Payout already paid' and return if resource.paid?
    redirect_to resource_path, notice: 'Payout is outdated' and return if resource.outdated?

    payout_method = resource.user.payout_methods.where(is_default: true, status: :done).first
    redirect_to resource_path, notice: 'No Payout info provided for user' and return unless payout_method

    begin
      case payout_method.provider
      when 'stripe'
        transfer = Stripe::Transfer.create({
                                             amount: resource.amount_cents,
                                             currency: 'usd',
                                             destination: payout_method.pid,
                                             description: resource.reference
                                           })
        resource.update(provider: :stripe, pid: transfer.id, status: :paid)
        payment_transactions = PaymentTransaction.where(payout_id: resource.id)
        payment_transactions.update_all(payout_status: :paid)
        PayoutMailer.payout_done({ amount: resource.amount_cents / 100.0 }, resource.user).deliver_later
      else
        redirect_to resource_path, notice: 'Wrong Payout info provided for user' and return unless payout_method
      end
    rescue StandardError => e
      resource.update(status: :failed)
      redirect_to resource_path, notice: "Can not make Payout for user: #{e.message}" and return
    end
    redirect_to resource_path, notice: 'Paid!'
  end

  action_item :pay, only: :show do
    link_to 'Pay', pay_service_admin_panel_payout_path(resource), method: :post unless resource.paid?
  end

  index do
    selectable_column
    id_column
    column :user
    column 'Amount' do |payout|
      (payout.amount_cents / 100.0).round(2)
    end
    column :amount_currency
    column :pid
    column :provider
    column :reference
    column :status
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :user_id
      f.input :amount_cents
      f.input :amount_currency
      f.input :reference
      f.input :provider
      f.input :status
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

    def scoped_collection
      if current_admin.platform_admin?
        super.joins(:user).where(users: { fake: false })
      else
        super
      end
    end
  end
end
