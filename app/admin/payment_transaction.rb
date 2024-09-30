# frozen_string_literal: true

ActiveAdmin.register PaymentTransaction do
  menu parent: 'Ledger'

  actions :all, except: (Rails.env.production? ? [:destroy] : [])
  member_action :refund, method: :post do
    refund_params = {}
    refund_params[:amount] = params[:amount].to_i if params[:amount].present?
    refund_params[:reason] = params[:reason] if params[:reason].present?
    begin
      resource.money_refund!(refund_params[:amount], refund_params[:reason])
      flash[:success] = 'Successfully refunded'
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_to resource_path(resource.id)
  end
  batch_action :mark_as_declined_payout do |ids|
    models = PaymentTransaction.where(id: ids)
    models.update_all(payout_status: :declined)

    redirect_to collection_path, alert: 'Payout Status updated'
  end
  batch_action :mark_as_success_payout do |ids|
    models = PaymentTransaction.where(id: ids)
    models.update_all(payout_status: :paid)

    redirect_to collection_path, alert: 'Payout Status updated'
  end
  batch_action :mark_as_pending_payout do |ids|
    models = PaymentTransaction.where(id: ids)
    models.update_all(payout_status: :pending)

    redirect_to collection_path, alert: 'Payout Status updated'
  end

  filter :purchased_item_type
  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :payout_id, label: 'Payout ID'
  filter :payout_status
  filter :type
  filter :archived
  filter :provider
  filter :pid
  filter :credit_card_last_4
  filter :status
  filter :payer_email
  filter :checked_at
  filter :created_at

  index do
    selectable_column
    column :id
    column :purchased_item
    column :status
    column :payout_status
    column :payout
    column :user
    column :provider
    column :pid do |obj|
      if obj.provider == 'stripe'
        link_to obj.pid, "https://dashboard.stripe.com/payments/#{obj.pid}", target: '_blank'
      else
        obj.pid
      end
    end
    column :checked_at
    column :credit_card_last_4
    column :card_type
    column :amount do |obj|
      (obj.amount / 100.0).round(2)
    end
    column :tax do |obj|
      (obj.tax_cents / 100.0).round(2)
    end
    column :total_amount do |obj|
      (obj.total_amount / 100.0).round(2)
    end
    column :type
    actions
  end

  show do
    columns do
      column do
        panel 'Payment Transaction Details' do
          attributes_table_for resource do
            row :id
            row :purchased_item
            row :purchased_item_type
            row :user
            row :type
            row :archived
            row :provider
            row :pid
            row :status
            row :payout_status
            row :payout
            row :checked_at
            row :amount do |obj|
              (obj.amount / 100.0).round(2)
            end
            row :tax do |obj|
              (obj.tax_cents / 100.0).round(2)
            end
            row :total_amount do |obj|
              (obj.total_amount / 100.0).round(2)
            end
            row :amount_currency
            row :credit_card_last_4
            row :card_type
            row :authorization_code
            row :payer_email
            row :zip
            row :country
            row :name_on_card
            row :created_at
            row :updated_at
          end
        end
      end
      column do
        panel 'Refund' do
          render partial: 'refund'
        end
        panel 'Refunds' do
          table_for resource.refunds do
            column :id
            column :amount do |obj|
              if resource.stripe?
                (obj.amount / 100.0).round(2)
              elsif resource.paypal?
                obj.amount.total
              end
            end
            # column :balance_transaction
            column :created_at do |obj|
              if resource.stripe?
                Time.at(obj.created)
              elsif resource.paypal?
                Time.parse(obj.create_time)
              end
            end
            column :reason
            column :status do |obj|
              if resource.stripe?
                obj.status
              elsif resource.paypal?
                obj.state
              end
            end
          end
        end
        panel 'Transaction Logs' do
          table_for resource.log_transactions.order(created_at: :desc) do
            column :id
            column :user
            column :amount
            column :type
            column 'Item', :abstract_session
            column :created_at
            column '' do |obj|
              link_to 'View', service_admin_panel_transaction_log_path(obj)
            end
          end
        end
      end
    end
  end
  form do |f|
    f.inputs do
      f.input :user_id, label: 'User ID'
      f.input :purchased_item_id, label: 'Purchased item ID'
      f.input :purchased_item_type, collection: PaymentTransaction::TYPES
      f.input :type, collection: TransactionTypes::ALL
      f.input :provider, collection: %w[paypal stripe]
      f.input :pid

      f.input :credit_card_last_4
      f.input :card_type
      f.input :amount, label: 'Amount(in Cents)'
      f.input :amount_currency, collection: ['usd']
      f.input :status, collection: PaymentTransaction::Statuses::ALL
      f.input :payer_email
      f.input :checked_at, as: :datepicker
      f.input :zip
      f.input :country
      f.input :name_on_card
      f.input :tax_cents, label: 'Tax Amount(in Cents)'

      f.input :archived
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
