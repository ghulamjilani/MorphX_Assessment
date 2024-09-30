# frozen_string_literal: true

ActiveAdmin.register Affiliate::Everflow::TrackedPayment do
  menu parent: 'Everflow Affiliate'

  actions :all

  filter :payment_transaction_user_id, label: 'User ID'
  filter :payment_transaction_user_email_cont, label: 'User email'
  filter :payment_transaction_user_display_name_cont, label: 'User name'
  filter :payment_transaction_id, label: 'Payment Transaction ID'
  filter :purchased_item_type, label: 'Purchased Item Type'
  filter :purchased_item_id, label: 'Purchased Item ID'
  filter :affiliate_everflow_transaction_id, label: 'Affiliate Everflow Transaction ID'
  filter :affiliate_everflow_transaction_transaction_id_cont, label: 'Transaction Code'
  filter :created_at

  index do
    selectable_column
    column :id
    column :user do |obj|
      link_to obj.payment_transaction.user.display_name, service_admin_panel_user_path(obj.payment_transaction.user)
    end
    column :payment_transaction do |obj|
      link_to "Payment Transaction ##{obj.payment_transaction.id}", service_admin_panel_payment_transaction_path(obj.payment_transaction)
    end
    column :purchased_item_type
    column :purchased_item do |obj|
      case obj.purchased_item_type
      when 'StripeDb::ServiceSubscription'
        link_to obj.purchased_item.stripe_plan.nickname, service_admin_panel_stripe_db_service_subscription_path(obj.purchased_item)
      end
    end
    column('Affiliate Transaction') do |obj|
      link_to obj.affiliate_everflow_transaction.transaction_id, service_admin_panel_affiliate_everflow_transaction_path(obj.affiliate_everflow_transaction)
    end
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.inputs do
      f.input :payment_transaction_id, label: 'Payment Transaction ID'
      f.input :purchased_item_type, as: :select, collection: Affiliate::Everflow::TrackedPayment::PURCHASED_ITEM_TYPES
      f.input :purchased_item_id, label: 'Purchased Item ID'
      f.input :affiliate_everflow_transaction_id, label: 'Everflow Transaction ID'
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
