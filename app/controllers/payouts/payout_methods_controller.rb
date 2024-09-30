# frozen_string_literal: true

class Payouts::PayoutMethodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_organization
  before_action :check_credentials

  def index
    @payout_methods = @current_organization.organizer.payout_methods.order(created_at: :desc)
  rescue StandardError => e
    Rails.logger.debug e.message
    @payout_methods = []
  end

  def create
    @payout_method = @user.payout_methods.create(
      business_type: params[:account][:business_type],
      provider: params[:account][:provider],
      country: params[:account][:country],
      status: :draft
    )
  end

  def edit
    @payout_method = @user.payout_methods.find(params[:id])
    @connect_account = @payout_method.connect_account&.stripe_item
  end

  def update
    @payout_method = @user.payout_methods.find(params[:id])

    if params[:primary] == '1'
      @current_organization.organizer.payout_methods.update_all(is_default: false)
      @payout_method.update(is_default: true)
    end

    case @payout_method.provider
    when 'stripe'
      @connect_account = @payout_method.connect_account&.stripe_item
      if @connect_account.blank?
        flash[:error] = I18n.t('controllers.payouts.payout_methods.errors.no_connect_account')
        redirect_to payouts_payout_methods_path and return
      end

      if params[:accept_tos] == '1'
        stripe_account_params = { tos_acceptance: { date: Time.now.to_i, ip: request.remote_ip, user_agent: request.user_agent } }
        Stripe::Account.update(@connect_account.id, stripe_account_params)
      end
    else
      raise 'Not Implemented'
    end

    redirect_to payouts_payout_methods_path
  end

  def destroy
    @payout_method = @user.payout_methods.find(params[:id])

    if @payout_method.pid.blank?
      @payout_method.destroy
      @current_organization.organizer.payout_methods.first&.update(is_default: true)
      return redirect_to payouts_payout_methods_path
    end

    case @payout_method.provider
    when 'stripe'
      @connect_account = @payout_method.connect_account
      Stripe::Account.delete(@connect_account.account_id) if @connect_account.present?
      @current_organization.organizer.payout_methods.first&.update(is_default: true) if @payout_method.is_default?
      @payout_method.destroy
    else
      raise 'Not Implemented'
    end
    redirect_to payouts_payout_methods_path
  end

  private

  def current_ability
    @current_ability ||= ::AbilityLib::OrganizationAbility.new(current_user)
  end

  def check_credentials
    authorize!(:manage_payment_method, @current_organization)
  end

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
    @user = @current_organization&.organizer
  end
end
