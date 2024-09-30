# frozen_string_literal: true

class Api::V1::User::ServiceSubscriptionsController < Api::V1::ApplicationController
  def index
    @subscriptions = current_user.service_subscriptions.order(created_at: :desc)
    @count = @subscriptions.count
    @subscriptions = @subscriptions.limit(@limit).offset(@offset)
  end

  def show
    @subscription = current_user.service_subscriptions.find(params[:id])
  end

  def current
    @subscription = current_user.service_subscriptions.where(service_status: %i[active trial trial_suspended suspended
                                                                                grace pending_deactivation])
                                .order(created_at: :desc)
                                .preload(stripe_plan: { plan_package: :feature_parameters }).first
    return render_json(404) if @subscription.blank?

    render :show
  end

  def create
    return render_json(403, 'You already have a subscription') unless can?(:subscribe_service_subscription, current_user)

    raise AccessForbiddenError unless !Rails.application.credentials.global.dig(:service_subscriptions, :purchase_permission_required) || current_user.can_buy_subscription?

    # Make user presenter
    current_user.create_presenter! if current_user.presenter.blank?

    current_user.presenter.update({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::PRICING })

    plan = StripeDb::ServicePlan.find_by(stripe_id: params[:plan_id])

    token = params[:stripe_token]
    stripe_card = params[:stripe_card]

    @coupon = StripeDb::Coupon.find_by(stripe_id: params[:coupon])
    if @coupon && !@coupon.valid_for?(plan)
      return render_json(403, I18n.t('controllers.api.v1.user.service_subscriptions.errors.coupon_not_applicable'))
    end

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
                 elsif stripe_card
                   current_user.find_stripe_customer_source(stripe_card)
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
      subscription_attrs = {
        customer: customer,
        # default_tax_rates: [tax], # Skip For now because we don't have tax
        items: [{ plan: plan.stripe_id }]
      }
      trial_from_plan = [1, '1', true, 'true'].include?(params[:trial])

      if trial_from_plan && cannot?(:have_trial_service_subscription, current_user)
        return render_json 422, I18n.t('controllers.api.v1.user.service_subscriptions.errors.already_used_trial')
      elsif trial_from_plan && plan.trial_period_days.to_i.zero?
        return render_json 422, I18n.t('controllers.api.v1.user.service_subscriptions.errors.plan_not_trial')
      end

      subscription_attrs[:coupon] = @coupon.stripe_id if @coupon
      subscription_attrs[:trial_period_days] = plan.trial_period_days.to_i if trial_from_plan
      stripe_subscription = Stripe::Subscription.create(subscription_attrs)
      @subscription = StripeDb::ServiceSubscription.create_or_update_from_stripe(stripe_subscription.id)

      if stripe_subscription.status == 'incomplete'
        @subscription.deactivate!
        return render_json(422, I18n.t('controllers.api.v1.user.service_subscriptions.errors.payment_failed'))
      end

      if @subscription.service_status.to_s != 'deactivated'
        current_user.can_use_wizard!
        current_user.cannot_buy_subscription!
        if @aef.present?
          @subscription.update(affiliate_everflow_transaction_id: @aef.id)
          # there was created first payment transaction after non trialing subscription creation
          # but we associate transaction with this subscription only after payment done
          @subscription.track_affiliate_transactions
        end
      end

      current_user.presenter.update({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP2 })
    rescue StandardError => e
      return render_json(422, e.message)
    end
    render :show
  end

  def update
    @subscription = current_user.service_subscriptions.find(params[:id])
    authorize!(:edit_by_business_plan, @subscription)

    if params[:cancel_trial].present?
      return render_json(401, I18n.t('controllers.api.v1.user.service_subscriptions.errors.subscription_not_trial')) unless @subscription.status == 'trialing'

      begin
        Stripe::Subscription.update(@subscription.stripe_id, { trial_end: 'now', payment_behavior: 'error_if_incomplete' })
      rescue StandardError => e
        case e.code
        when 'resource_missing'
          return render_json(422, I18n.t('controllers.api.v1.user.service_subscriptions.errors.resource_missing'))
        when 'card_declined'
          return render_json(422, I18n.t('controllers.api.v1.user.service_subscriptions.errors.payment_failed'))
        else
          return render_json(422, e.message)
        end
      end
    end

    if params[:cancel_at_period_end].present?
      Stripe::Subscription.update(@subscription.stripe_id, { cancel_at_period_end: false })
      @subscription.activate!
    end

    if params[:plan_id].present?
      plan = StripeDb::ServicePlan.joins(:plan_package).active.where(id: params[:plan_id], plan_packages: { active: true }).first
      return render_json(404, I18n.t('controllers.api.v1.user.service_subscriptions.errors.plan_not_found')) unless plan

      begin
        @subscription.change_plan!(plan.id)
      rescue StandardError => e
        return render_json(422, e.message)
      end
    end

    @subscription.reload

    render :show
  end

  def destroy
    @subscription = current_user.service_subscriptions.find(params[:id])
    authorize!(:edit_by_business_plan, @subscription)
    if %w[trial trial_suspended grace suspended].include?(@subscription.service_status)
      if %w[grace suspended].include?(@subscription.service_status)
        ServiceSubscriptionsMailer.canceled(@subscription.id).deliver_later
      end
      @subscription.deactivate!
    else
      Stripe::Subscription.update(@subscription.stripe_id, { cancel_at_period_end: true })
      @subscription.pending_deactivation!
    end

    head :ok
  end

  def pay
    @subscription = current_user.service_subscriptions.find(params[:id])
    authorize!(:edit_by_business_plan, @subscription)
    begin
      Stripe::Invoice.pay(@subscription.stripe_item.latest_invoice)
      @subscription.reload
      render :show
    rescue StandardError
      # sync subscription state with stripe
      StripeDb::ServiceSubscription.create_or_update_from_stripe(@subscription.stripe_id)
      @subscription.reload
      if @subscription.service_status == 'active'
        render :show
      else
        return render_json(422, I18n.t('controllers.api.v1.user.service_subscriptions.errors.payment_failed'))
      end
    end
  end

  def apply_coupon
    @plan = StripeDb::ServicePlan.active.find_by(stripe_id: params[:plan_id])
    @coupon = StripeDb::Coupon.find_by(stripe_id: params[:coupon])

    return render_json(404, I18n.t('controllers.api.v1.user.service_subscriptions.errors.coupon_not_found')) unless @coupon
    return render_json(403, I18n.t('controllers.api.v1.user.service_subscriptions.errors.coupon_not_applicable')) unless @coupon.valid_for?(@plan)

    @savings = @coupon.calc_savings(@plan.amount)
    @total = @plan.amount - @savings
  end
end
