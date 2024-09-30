# frozen_string_literal: true

ActiveAdmin.register Plutus::CreditAmount do
  config.batch_actions = false

  menu false
  actions :all, except: %i[new create destroy]
  form do |f|
    f.inputs do
      f.input :account
      f.input :amount
    end
    f.actions
  end
  controller do
    def permitted_params
      params.permit!
    end

    def update
      object = Plutus::CreditAmount.find(params[:id])

      attributes = permitted_params[:credit_amount]
      object.attributes = attributes
      if object.save
        flash[:success] = 'CreditAmount successfully updated'
      else
        flash[:info] = object.errors.full_messages.join('. ')
        object.save(validate: false)
      end

      redirect_to service_admin_panel_plutus_entry_path(object.entry)
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
