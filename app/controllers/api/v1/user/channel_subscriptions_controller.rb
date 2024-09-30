# frozen_string_literal: true

class Api::V1::User::ChannelSubscriptionsController < Api::V1::ApplicationController
  def index
    @subscriptions = current_user.channels_subscriptions
    @count = @subscriptions.count
    @subscriptions = @subscriptions.limit(@limit).offset(@offset)
  end

  def show
    @subscription = current_user.channels_subscriptions.find(params[:id])
  end

  # render_json(401, 'Plan is not available anymore') unless plan
  def create
    plan = StripeDb::Plan.active.find(params[:plan_id])
    organization = plan.channel_subscription.channel.organization
    if current_ability.cannot?(:monetize_content_by_business_plan, organization)
      return render_json(422, 'Payments are not allowed')
    end
    # Error if no recipient on gift
    return render_json(422, 'Please enter recipient email') if params[:gift] && !params[:recipient]

    # Prepare recipient
    if params[:recipient].present?
      recipient = ::User.find_or_initialize_by(email: params[:recipient].strip.downcase)
      if recipient.persisted?
        # Error if recipient already subscribed
        return render_json(422, "#{recipient.public_display_name} has been already subscribed") unless can?(
          :subscribe_as_gift_for, recipient, plan.channel_subscription
        )
      elsif recipient.validate && recipient.errors.key?(:email)
        return render_json(422, "Email: #{recipient.email} is invalid")
      else
        recipient.before_create_generic_callbacks_and_skip_validation
        recipient.skip_confirmation_notification!
        recipient.skip_invitation = true
        begin
          recipient.save!(validate: false)
        rescue StandardError => e
          return render_json(422, e.message)
        end
      end
    elsif cannot?(:subscribe, plan.channel_subscription)
      error = if can?(:unsubscribe, plan.channel_subscription)
                "You've been already subscribed"
              elsif plan.channel_subscription.user == current_user
                "You can't subscribe because you're owner"
              end
      return render_json(422, error)
    end
    token = params[:stripe_token]

    # country = params[:country].to_s.downcase
    # zip_code = params[:zip_code].to_i
    # TODO: уточнить по налогам актуального штата. Пока у нас безналоговый штат
    tax = 0 # country == 'us' && zip_code >= 75000 && zip_code <= 79999 ? 8.25 : 0

    # associate with user and save everflow transaction ID
    if Rails.application.credentials.backend.dig(:initialize, :everflow, :enabled) && cookies[:ef_transaction_id].present?
      @aef = current_user.affiliate_everflow_transactions.find_or_create_by(transaction_id: cookies[:ef_transaction_id])
    end

    # Init customer
    begin
      if current_user.has_payment_info?
        # check if this is not existing card token
        customer = current_user.stripe_customer
        source = if token&.start_with?('tok_')
                   Stripe::Customer.create_source(customer.id, { source: token })
                 elsif token&.start_with?('card_')
                   current_user.find_stripe_customer_source(token)
                 end
        if source
          customer.default_source = source
          customer.save
        end
      else
        customer = Stripe::Customer.create(
          email: current_user.email,
          description: current_user.public_display_name,
          source: token
        )
        current_user.stripe_customer_id = customer.id
        current_user.save(validate: false)
      end

      # don't use trial for gifts and for users who already was subscribed to this channel with any plan
      trial_from_plan = recipient.blank? && can?(:have_trial, plan.channel_subscription.channel)
      subscription_attrs = {
        customer: customer,
        # default_tax_rates: [tax], # Skip For now because we don't have tax
        items: [{ plan: plan.stripe_id }],
        cancel_at_period_end: recipient.present? || !plan.autorenew,
        metadata: { gift: recipient.present?, recipient: recipient.try(:id) }
      }
      subscription_attrs[:trial_end] =
        (trial_from_plan && !plan.trial_period_days.to_i.zero?) ? plan.trial_period_days.to_i.days.from_now.to_i : 'now'
      stripe_subscription = Stripe::Subscription.create(subscription_attrs)

      @subscription = StripeDb::Subscription.create_or_update_from_stripe(stripe_subscription.id)
      @subscription.user = recipient || current_user
      @subscription.save

      if @aef.present?
        @subscription.update(affiliate_everflow_transaction_id: @aef.id)
        # there was created first payment transaction after non trialing subscription creation
        # but we associate transaction with this subscription only after payment done
        @subscription.track_affiliate_transactions
      end

      if %w[active trialing].include?(@subscription.status)
        @message = if recipient
                     I18n.t('controllers.api.v1.user.channel_subscriptions.create.success_gift', user_name: recipient.public_display_name, plan_name: plan.im_name)
                   else
                     I18n.t('controllers.api.v1.user.channel_subscriptions.create.success', plan_name: plan.im_name)
                   end
      else
        @subscription.stripe_item.delete
        raise I18n.t('controllers.api.v1.user.channel_subscriptions.create.error')
      end
    rescue StandardError => e
      return render_json(422, e.message)
    end
    render :show
  end

  def check_recipient_email
    @message = ''
    if params[:email].blank?
      @message = 'Email is blank'
      @is_valid = false
    else
      @user = ::User.find_or_initialize_by(email: params[:email].strip.downcase)
      subscription = Subscription.find(params[:id])
      if @user.persisted?
        if can?(:subscribe_as_gift_for, @user, subscription)
          @is_valid = true
        else
          @message = 'User already subscribed'
          @is_valid = false
        end
      elsif !@user.validate && @user.errors.key?(:email)
        @message = 'Email is wrong'
        @is_valid = false
      else
        @is_valid = true
      end
    end
  end
end
