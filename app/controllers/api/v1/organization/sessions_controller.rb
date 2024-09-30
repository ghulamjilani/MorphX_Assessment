# frozen_string_literal: true

class Api::V1::Organization::SessionsController < Api::V1::Organization::ApplicationController
  before_action :set_session, only: %i[show update destroy]

  def index
    query = current_organization.sessions
    @count = query.count
    @sessions = query.limit(@limit).offset(@offset)
  end

  def show
  end

  # Create obs
  # {"channel_id"=>"1",
  # "livestream"=> true,
  # "livestream_free"=> true,
  # "title"=>"Gürhard Stanley Live Session",
  # "description"=>"",
  # "custom_description_field_value"=>"",
  # "record"=>"true",
  # "recorded_free"=>"true",
  # "recorded_access_cost"=>"0",
  # "allow_chat"=>"on",
  # "private"=>"false",
  # "duration"=>"30",
  # "start_now"=>"true",
  # "pre_time"=>"0",
  # "presenter_id"=>"1",
  # "autostart"=>"true",
  # "device_type"=>"studio_equipment",
  # "service_type"=>"rtmp",
  # "immersive"=> false,
  # adult: 0,
  # "start_at" => Time.now + rand(10000).minutes}
  def create
    presenter = current_organization.employees.find(params[:user_id]).presenter
    channel   = current_organization.channels.find(params[:channel_id])
    @session = current_organization.sessions.build(session_params) do |session|
      session.livestream = true
      session.livestream_free = true
      session.recorded_free = true
      session.private = false
      session.presenter = presenter if presenter
      session.channel = channel
      session.immersive = false
      session.level = 'All Levels'
      session.adult = 0
      if session.ffmpegservice_account_id.blank? && Room::ServiceTypes::MOBILE == session.service_type
        session.ffmpegservice_account = current_organization.find_or_assign_wa(user_id: session.presenter.user_id,
                                                                       service_type: Room::ServiceTypes::MOBILE)
      end
    end
    @session.save!
    if Rails.env.development?
      begin
        @session.reload.room.ffmpegservice_account.stream_up!
      rescue StandardError
        nil
      end
    end
    render :show
  end

  def update
    @session.update!(session_params)
    render :show
  end

  def destroy
    @session.destroy
    render :show
  end

  private

  def set_session
    @session = current_organization.sessions.find(params[:id])
  end

  def session_params
    params.require(:session).permit(
      :title,
      :description,
      :record,
      :allow_chat,
      :duration,
      :pre_time,
      :autostart,
      :device_type,
      :service_type,
      :start_at,
      :channel_id,
      :ffmpegservice_account_id
    )
  end
end
