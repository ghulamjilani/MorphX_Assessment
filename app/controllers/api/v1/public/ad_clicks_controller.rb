# frozen_string_literal: true

class Api::V1::Public::AdClicksController < Api::V1::Public::ApplicationController
  def create
    AdClick.create!(user_id: current_user&.id, pb_ad_banner_id: params[:ad_banner_id])

    head :ok
  end
end
