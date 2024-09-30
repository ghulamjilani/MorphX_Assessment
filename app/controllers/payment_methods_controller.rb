# frozen_string_literal: true

class PaymentMethodsController < ActionController::Base
  before_action :authenticate_user!

  def update
    unless current_user.has_payment_info?
      flash[:error] = 'Access Denied'
      redirect_to edit_billing_profile_path and return
    end
    primary = params[:primary] == '1'
    begin
      card = current_user.find_stripe_customer_source(params[:id])
      if primary
        current_user.stripe_customer.default_source = card
        current_user.stripe_customer.save
      end
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_to edit_billing_profile_path
  end

  def create
    token = params[:stripe_token]
    unless token
      flash[:error] = 'Invalid card token'
      redirect_to edit_billing_profile_path and return
    end
    begin
      # Check if user has stripe customer entity
      if current_user.has_payment_info?
        primary = params[:primary] == '1'
        # check if this is not existing card token
        token_obj = Stripe::Token.retrieve(token)
        existing_card = current_user.stripe_customer_sources.detect do |source|
          credit_card = source.is_a?(Stripe::Source) ? source.card : source
          credit_card.last4 == token_obj.card.last4
        end
        if existing_card.present?
          flash[:error] = "#{token_obj.card.last4} card already exists"
          redirect_to edit_billing_profile_path and return
        end
        source = Stripe::Customer.create_source(current_user.stripe_customer_id, { source: token })
        current_user.stripe_customer.default_source = source if source && primary
        current_user.stripe_customer.save
      else
        customer = Stripe::Customer.create(
          email: current_user.email,
          description: current_user.public_display_name,
          source: token
        )
        current_user.stripe_customer_id = customer.id
        current_user.save(validate: false)
      end
      flash[:success] = 'Card was successfully added'
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_to edit_billing_profile_path
  end

  def destroy
    unless current_user.has_payment_info?
      flash[:error] = 'Access Denied'
      redirect_to edit_billing_profile_path and return
    end
    begin
      current_user.find_stripe_customer_source(params[:id]).delete
      flash[:success] = I18n.t('controllers.payment_method_removed')
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_to edit_billing_profile_path
  end
end
