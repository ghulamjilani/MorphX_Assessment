# frozen_string_literal: true

class Api::V1::System::WebpushController < Api::V1::ApplicationController
  skip_before_action :authorization, if: -> { request.headers['Authorization'].blank? }

  def create
    @subscription = Webpush::Subscription.find_or_initialize_by(auth: params[:keys][:auth])
    @subscription.endpoint = params[:endpoint]
    @subscription.p256dh = params[:keys][:p256dh]
    @subscription.user_id ||= current_user&.id
    @subscription.save!
    render json: @subscription, status: :created
  rescue StandardError => e
    render json: { message: e.message }, status: 422
  end
end
