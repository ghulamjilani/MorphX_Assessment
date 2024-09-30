# frozen_string_literal: true

class Dashboard::SubscriptionsController < Dashboard::ApplicationController
  before_action :check_subscription
  before_action :check_credentials
  before_action :channels_and_plans, only: %i[new create edit update]

  respond_to :json

  def index
    @subscriptions = Subscription.joins(:channel).where(channels: { organization_id: current_user.current_organization_id }).order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json { render json: @subscriptions }
    end
  end

  def new
    @subscription = Subscription.new
    @subscription.plans =
      [
        { im_name: 'Plan - 1', im_color: '#0000ff', interval: 'month', interval_count: 1 },
        { im_name: 'Plan - 2', im_color: '#ffff00', interval: 'month', interval_count: 3 },
        { im_name: 'Plan - 3', im_color: '#008000', interval: 'month', interval_count: 6 },
        { im_name: 'Plan - 4', im_color: '#ff0000', interval: 'month', interval_count: 12 }
      ].map { |hash| StripeDb::Plan.new(hash) }
    respond_to(&:html)
  end

  def edit
    @subscription = Subscription.joins(:channel).where(channels: { organization_id: current_user.current_organization_id }).find(params[:id])
    if @subscription.channel.archived?
      @subscription.channel.send(:archive_subscription)
      flash[:error] = 'Channel is Archived'
      redirect_to dashboard_subscriptions_path and return
    end
    @plans = @subscription.plans.active.order(amount: :asc)
    respond_to(&:html)
  end

  def update
    @subscription = Subscription.joins(:channel).where(channels: { organization_id: current_user.current_organization_id }).find(params[:id])
    if @subscription.update(update_subscription_params)
      respond_to do |format|
        format.html { redirect_to dashboard_subscriptions_path }
      end
    else
      respond_to do |format|
        format.html do
          @plans = @subscription.plans.active.order(amount: :asc)
          flash[:error] = @subscription.errors.full_messages.join('. ')
          render :edit, status: 422
        end
      end
    end
  end

  def create
    @channel = current_user.current_organization.channels.find(params[:subscription][:channel_id])
    @channel.create_stripe_product! if @channel.stripe_id.blank?
    ActiveRecord::Base.transaction do
      @subscription = current_user.subscriptions.create!(create_subscription_params.except(:plans_attributes))
      @subscription.update!(create_subscription_params)
    end
    respond_to do |format|
      format.html { redirect_to dashboard_subscriptions_path }
    end
  rescue StandardError => e
    respond_to do |format|
      format.html do
        render :new, flash: { error: @subscription&.errors&.full_messages&.join('. ') || e.message }, status: 422
      end
    end
  end

  private

  def create_subscription_params
    if params[:subscription].present?
      params.require(:subscription).permit(
        :id,
        :channel_id,
        :description,
        :enabled,
        plans_attributes: %i[
          id
          im_name
          im_color
          im_livestreams
          im_interactives
          im_replays
          im_uploads
          im_documents
          im_enabled
          interval
          interval_count
          amount
          autorenew
          trial_period_days
        ]
      ).tap do |attributes|
        attributes[:plans_attributes].reject! do |_i, plan|
          [0, '0', false, 'false'].include?(plan[:im_enabled])
        end
        attributes[:plans_attributes].each_pair do |_k, plan|
          plan[:trial_period_days] = plan[:trial_period_days].to_i
          plan[:interval_count] = plan[:interval_count].to_i
        end
      end
    end
  end

  def update_subscription_params
    if params[:subscription].present?
      params.require(:subscription).permit(
        :id,
        :channel_id,
        :description,
        :enabled,
        plans_attributes: %i[
          id
          im_name
          im_color
          im_livestreams
          im_interactives
          im_replays
          im_uploads
          im_documents
          im_channel_conversation
          im_enabled
          interval
          interval_count
          amount
          autorenew
          trial_period_days
        ]
      ).tap do |attributes|
        attributes[:plans_attributes].reject! do |_i, plan|
          plan[:id].blank? && [0, '0', false, 'false'].include?(plan[:im_enabled])
        end
        attributes[:plans_attributes].each_pair do |_i, plan|
          plan[:trial_period_days] ||= 0
          plan[:interval_count] = plan[:interval_count].to_i
        end
      end
    end
  end

  def channels_and_plans
    @channels = current_user.organization_channels_with_credentials(current_user.current_organization, ::AccessManagement::Credential::Codes::MANAGE_CHANNEL_SUBSCRIPTION).approved.order('channels.title ASC')
    @plans = StripeDb::Plan.where(channel_subscription_id: params[:id])
  end

  def check_subscription
    return redirect_to dashboard_path if cannot?(:monetize_content_by_business_plan, current_user.current_organization)
  end

  def check_credentials
    return redirect_to dashboard_path if cannot?(:manage_channel_subscription, current_user.current_organization)
  end
end
