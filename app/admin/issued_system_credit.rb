# frozen_string_literal: true

ActiveAdmin.register IssuedSystemCredit do
  menu parent: 'Ledger'

  index do
    column :id
    column :type
    column :participant
    column :amount
    column :status
    column :created_at

    actions
  end

  filter :id
  filter :type
  filter :participant,
         as: :select,
         collection: proc { IssuedSystemCredit.select('participant_id').uniq.collect(&:participant) }
  filter :status

  actions :all, except: %i[destroy credit edit update destroy]

  controller do
    def permitted_params
      params.permit!
    end

    def new
      render 'service_admin_panel/issued_system_credits/new', layout: 'active_admin'
    end

    def create
      user = User.find_by(email: params[:email].to_s.downcase)
      if user.blank?
        flash.now[:error] = %(Can not find user with "#{params[:email]}" email)
        render 'service_admin_panel/issued_system_credits/new', layout: 'active_admin'
        return
      end

      system_credit_refund_amount = params[:system_credit_refund_amount].to_f
      unless system_credit_refund_amount.positive?
        flash.now[:error] = 'Refund amount must be positive numeric value'
        render 'service_admin_panel/issued_system_credits/new', layout: 'active_admin'
        return
      end

      @credit = Csr.new(user).issue_system_credit_refund(system_credit_refund_amount)
      if @credit
        redirect_to service_admin_panel_issued_system_credit_path(@credit),
                    notice: 'System credit refund has been saved'
      else
        render 'service_admin_panel/issued_system_credits/new', layout: 'active_admin'
      end
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
