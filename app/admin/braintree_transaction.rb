# frozen_string_literal: true

# TODO: remove old unused piece of code
ActiveAdmin.register BraintreeTransaction do
  menu parent: 'Ledger'

  actions :all, except: %i[new edit create edit update destroy]
  form do |f|
    f.inputs do
      f.input :amount
      f.input :abstract_session
      f.input :credit_card_last_4
      f.input :user
      f.input :braintree_id
      f.input :status
      f.input :checked_at
      f.input :type
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit!
    end

    # NOTE: it probably deserve its own custom action instead
    # but I'm not sure yet how to add one to active_admin
    def update
      braintree_transaction = BraintreeTransaction.find(params[:id])

      interactor = Csr.new(braintree_transaction.user)
      if interactor.refund_braintree_transaction(braintree_transaction, params[:amount]) == true
        flash[:success] = interactor.success_message
      else
        flash[:error] = interactor.error_message
      end

      redirect_to service_admin_panel_braintree_transaction_path(braintree_transaction.id)
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end

  show do
    transaction_result = Braintree::Transaction.find(resource.braintree_id)

    resource.status     = transaction_result.status
    resource.checked_at = Time.zone.now
    resource.save(validate: false)

    render partial: 'show'
  end
end
