# frozen_string_literal: true

class Stripe::SubscriptionsController < ApplicationController
  before_action :authenticate_user!, except: [:preview_plans]
  before_action :load_plan, only: %i[new create]

  def new
    redirect_back fallback_location: root_path
  end

  def create
    @plan = StripeDb::Plan.active.find_by(id: params[:plan_id])
    organization = @plan.channel_subscription.channel.organization
    if cannot?(:monetize_content_by_business_plan, organization)
      flash[:error] = 'Payments are not allowed'
      return redirect_back fallback_location: root_path
    end
    unless @plan
      flash[:error] = 'Plan is not available anymore'
      return redirect_back fallback_location: root_path
    end
    if params[:gift] && !params[:recipient]
      flash[:error] = 'Please enter recipient email'
      return redirect_back fallback_location: root_path
    end
    if params[:recipient].present?
      @recipient = User.find_or_initialize_by(email: params[:recipient].strip.downcase)
      if @recipient.persisted?
        unless can?(:subscribe_as_gift_for, @recipient, @plan.channel_subscription)
          flash[:error] = "#{@recipient.public_display_name} has been already subscribed"
          return redirect_back fallback_location: root_path
        end
      elsif @recipient.validate && @recipient.errors.has_key?(:email)
        flash[:error] = "Email: #{@recipient.email} is invalid"
        return redirect_back fallback_location: root_path
      else
        @recipient.before_create_generic_callbacks_and_skip_validation
        @recipient.skip_confirmation_notification!
        @recipient.skip_invitation = true
        begin
          @recipient.save!(validate: false)
        rescue StandardError => e
          flash[:error] = e.message
          return redirect_back fallback_location: root_path
        end
      end
    elsif cannot?(:subscribe, @plan.channel_subscription)
      flash[:error] = if can?(:unsubscribe, @plan.channel_subscription)
                        "You've been already subscribed"
                      elsif @plan.channel_subscription.user == current_user
                        "You can't subscribe because you're owner"
                      end
      return redirect_back fallback_location: root_path
    end
    @plan_owner = @plan.channel_subscription.user
    country = params[:country].to_s.downcase
    zip_code = params[:zip_code].to_i
    token = params[:stripe_token]
    # TODO: уточнить по налогам актуального штата
    tax = 0 # country == 'us' && zip_code >= 75000 && zip_code <= 79999 ? 8.25 : 0

    # associate with user and save everflow transaction ID
    if Rails.application.credentials.backend.dig(:initialize, :everflow, :enabled) && cookies[:ef_transaction_id].present?
      @aef = current_user.affiliate_everflow_transactions.find_or_create_by(transaction_id: cookies[:ef_transaction_id])
    end

    # Init customer
    begin
      if current_user.has_payment_info?
        # check if this is not existing card token
        @customer = current_user.stripe_customer
        @source = if token&.start_with?('tok_')
                    Stripe::Customer.create_source(@customer.id, { source: token })
                  elsif token&.start_with?('card_')
                    current_user.find_stripe_customer_source(token)
                  end
        if @source
          @customer.default_source = @source
          @customer.save
        end
      else
        @customer = Stripe::Customer.create(
          email: current_user.email,
          description: current_user.public_display_name,
          source: token
        )
        current_user.stripe_customer_id = @customer.id
        current_user.save(validate: false)
      end

      # don't use trial for gifts and for users who already was subscribed to this channel with any plan
      @trial_from_plan = @recipient.blank? && can?(:have_trial, @plan.channel_subscription.channel)
      subscription_attrs = {
        customer: @customer,
        # default_tax_rates: [tax], # Skip For now because we don't have tax
        items: [{ plan: @plan.stripe_id }],
        cancel_at_period_end: @recipient.present? || !@plan.autorenew,
        metadata: { gift: @recipient.present?, recipient: @recipient.try(:id) }
      }
      subscription_attrs[:trial_end] =
        (@trial_from_plan && !@plan.trial_period_days.to_i.zero?) ? @plan.trial_period_days.to_i.days.from_now.to_i : 'now'

      @stripe_subscription = Stripe::Subscription.create(subscription_attrs)
      @subscription = StripeDb::Subscription.create_or_update_from_stripe(@stripe_subscription.id)
      @subscription.user = @recipient || current_user
      @subscription.save

      if @aef.present?
        @subscription.update(affiliate_everflow_transaction_id: @aef.id)
        # there was created first payment transaction after non trialing subscription creation
        # but we associate transaction with this subscription only after payment done
        @subscription.track_affiliate_transactions
      end

      if %w[active trialing].include?(@subscription.status)
        flash[:success] = if @recipient
                            I18n.t('controllers.api.v1.user.channel_subscriptions.create.success_gift', user_name: @recipient.public_display_name, plan_name: @plan.im_name)
                          else
                            I18n.t('controllers.api.v1.user.channel_subscriptions.create.success', plan_name: @plan.im_name)
                          end
      else
        @subscription.stripe_item.delete
        raise I18n.t('controllers.api.v1.user.channel_subscriptions.create.error')
      end
    rescue StandardError => e
      flash[:error] = e.message
    end
    redirect_back fallback_location: root_path
  end

  def unsubscribe
    @subscription = StripeDb::Subscription.find(params[:id])
    Stripe::Subscription.update(@subscription.stripe_id, { cancel_at_period_end: true })
    StripeDb::Subscription.create_or_update_from_stripe(@subscription.stripe_id)
    @subscription.reload
    end_of_period = DateTime.strptime(@subscription.stripe_item.current_period_end.to_s, '%s')
                            .in_time_zone(current_user.timezone).strftime('%d %b %I:%M %p %Z')
    flash[:success] = "Successfully unsubscribed! Subscription will be closed at the end of period: #{end_of_period}"
    redirect_back fallback_location: root_path
  end

  def preview_plans
    @subscription = Subscription.find(params[:id])
    @plans = @subscription.plans.active.order(amount: :asc)
    respond_to do |format|
      format.js
      format.html do
        @channel = @subscription.channel
        redirect_to @channel.relative_path
      end
    end
  end

  def preview_purchase
    if current_user.email.blank?
      flash[:error] = 'Please provide email'
      respond_to do |format|
        format.js { render js: "window.eventHub.$emit('open-modal:auth', 'more-info')" }
        format.html { redirect_to edit_application_profile_path }
      end
      return
    end
    @subscription = Subscription.find(params[:id])
    @plan = @subscription.plans.active.find_by(id: params[:plan_id])
    flash[:error] = 'Plan is not available anymore' unless @plan
    respond_to do |format|
      format.js
      format.html do
        @channel = @subscription.channel
        redirect_to @channel.relative_path
      end
    end
  end

  def check_recipient_email
    user = User.find_or_initialize_by(email: params[:email].strip.downcase)
    subscription = Subscription.find(params[:id])
    message = ''
    is_valid = if user.persisted?
                 if can?(:subscribe_as_gift_for, user, subscription)
                   true
                 else
                   message = 'User already subscribed'
                   false
                 end
               elsif !user.validate && user.errors.has_key?(:email)
                 message = 'Email is wrong'
                 false
               else
                 true
               end
    render json: { is_valid: is_valid, name: (user.persisted? ? user.public_display_name : 'New User'),
                   email: user.email, message: message }
  end

  private

  def load_plan
    @plan = StripeDb::Plan.where(im_enabled: true).find_by!(id: params[:plan_id])
  end
end
