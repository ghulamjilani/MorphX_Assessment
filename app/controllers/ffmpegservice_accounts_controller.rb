# frozen_string_literal: true

class FfmpegserviceAccountsController < ApplicationController
  before_action :authenticate_user!

  def create
    if current_user.all_channels.pluck(:organization_id).include?(params[:organization_id].to_i)
      organization = Organization.find(params[:organization_id])
    end

    raise 'User does not have access to organization' if organization.blank?

    wa_type = organization.ffmpegservice_transcode ? 'paid' : 'free'
    wa_service = organization.wa_service_by(service_type: params[:service_type])
    wa = organization.ffmpegservice_account(
      current_service: wa_service,
      type: wa_type,
      user_id: current_user.id
    ) || organization.assign_ffmpegservice_account(
      current_service: wa_service,
      type: wa_type,
      user_id: current_user.id
    )

    raise 'Cannot find or assign proper wa' if wa.blank?

    if params[:service_type] == 'ipcam'
      ipcam_url = params[:ipcam_url].strip
      unless wa.update_attribute(:source_url, ipcam_url)
        flash[:error] = 'Source url is invalid'
      end
    end

    render json: wa.attributes.delete_if { |key, _value|
                   %w[id server port stream_name username password source_url sandbox current_service].exclude?(key)
                 }
  rescue StandardError => e
    notify_airbrake(e)
    head 404
  end

  def stop_stream
    if (wa = current_user.ffmpegservice_accounts.find(params[:id]))
      if wa.sandbox
        wa.stream_off!
        flash[:success] = 'Sandbox stream is stopped, please reload the page'
      else
        Sender::Ffmpegservice.client(account: wa).stop_stream
      end
    end
    head :ok
  rescue StandardError => e
    notify_airbrake(e)
    render json: { message: e.message }, status: 500
  end

  def start_stream
    if (wa = current_user.ffmpegservice_accounts.find(params[:id]))
      if wa.sandbox
        wa.stream_up!
        flash[:success] = 'Sandbox stream is started, please reload the page'
      else
        Sender::Ffmpegservice.client(account: wa).start_stream
        StopFfmpegserviceStream.perform_at(15.minutes.from_now, wa.id)

        ResqueApi.enqueue_at(1.seconds.from_now, ResqueAPIStub.create('StreamJob::FfmpegserviceStatus', 'normal'), wa.id,
                             15.minutes.from_now.utc)
      end
    end
    head :ok
  rescue StandardError => e
    notify_airbrake(e)
    render json: { message: e.message }, status: 500
  end

  def find_or_assign
    raise 'unknown service_type' unless [Room::ServiceTypes::RTMP, Room::ServiceTypes::IPCAM,
                                         Room::ServiceTypes::WEBRTC, Room::ServiceTypes::MOBILE].include?(params[:service_type].to_s)

    channel = current_user.all_channels.find(params[:channel_id])
    presenter = Presenter.find(params[:presenter_id])
    service_type = params[:service_type].to_s

    user = presenter.user
    organization = channel.organization
    current_service = organization.wa_service_by(service_type: service_type)
    relation = organization.ffmpegservice_accounts.where(current_service: current_service,
                                                 transcoder_type: ((organization.ffmpegservice_transcode || current_service.to_sym == :webrtc) ? 'transcoded' : 'passthrough')).order('sandbox asc')
    unless params[:id].present? && (wa = relation.find_by(id: params[:id]))
      wa = if %w[main webrtc mobile].include?(current_service.to_s)
             relation.find_by(user_id: user.id)
           else
             relation.first
           end
    end

    unless wa
      type = (organization.ffmpegservice_transcode || current_service.to_sym == :webrtc) ? :paid : :free
      wa = organization.assign_ffmpegservice_account(current_service: current_service, type: type, user_id: user.id)
    end

    if wa
      render json: { id: wa.id, current_service: wa.current_service, sandbox: wa.sandbox }
    else
      render json: { error: 'Cannot assign new streaming account. Please try again later.' }, status: 422
    end
  end

  def find
    channel = current_user.all_channels.find(params[:channel_id])
    presenter = Presenter.find(params[:presenter_id])
    raise 'unknown service_type' unless [Room::ServiceTypes::RTMP, Room::ServiceTypes::IPCAM,
                                         Room::ServiceTypes::WEBRTC, Room::ServiceTypes::MOBILE].include?(params[:service_type].to_s)

    service_type = params[:service_type].to_s

    user = presenter.user
    organization = channel.organization
    current_service = organization.wa_service_by(service_type: service_type)
    relation = organization.ffmpegservice_accounts.where(current_service: current_service, transcoder_type: (organization.ffmpegservice_transcode ? 'transcoded' : 'passthrough')).order('sandbox asc')

    unless params[:id].present? && (wa = relation.find_by(id: params[:id]))
      wa = if %w[main webrtc mobile].include?(current_service)
             relation.find_by(user_id: user.id)
           else
             relation.first
           end
    end

    if wa
      render json: { id: wa.id, current_service: wa.current_service, sandbox: wa.sandbox }
    else
      render json: { error: 'Cannot assign new streaming account. Please try again later.' }, status: 422
    end
  end
end
