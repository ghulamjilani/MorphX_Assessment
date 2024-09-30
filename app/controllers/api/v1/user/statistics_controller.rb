# frozen_string_literal: true

class Api::V1::User::StatisticsController < Api::V1::ApplicationController
  def index
    @organization = current_user.organization
    render_json(404, 'Organization is nil') and return unless @organization

    @creators_subscription = current_user.service_subscriptions.where(status: :active).order(created_at: :desc)
                                         .limit(1).preload(stripe_plan: :plan_package).first
    @channels = @organization.channels.approved.not_archived.order(created_at: :desc).preload(channel_invited_presenterships: { presenter: :user })
  end
end
