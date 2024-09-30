# frozen_string_literal: true

class ReplenishmentsController < ApplicationController
  before_action :authenticate_user!

  def new
    @charge_amount = params[:amount]

    generate_client_token
  end

  def create
    interactor = PresenterCreditReplenishment.new(current_user, params[:amount])
    interactor.execute(params[:payment_method_nonce])
    if interactor.success_message
      flash[:success] = interactor.success_message
      redirect_to earnings_dashboard_money_index_path
    else
      flash.now[:error] = interactor.error_message
      Rails.logger.debug interactor.error_message.inspect

      @charge_amount = interactor.charge_amount

      generate_client_token
      render 'new'
    end
  end
end
