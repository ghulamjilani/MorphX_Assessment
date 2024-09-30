# frozen_string_literal: true

class Api::V1::User::StreamPreviewsController < Api::V1::User::ApplicationController
  before_action :authorization_for_own_organization
  before_action :set_stream_preview, only: %i[show destroy]
  before_action :set_ffmpegservice_account, only: [:create]

  def index
    query = own_organization.stream_previews
    query = query.where(ffmpegservice_account_id: params[:ffmpegservice_account_id]) if params[:ffmpegservice_account_id].present?
    query = query.where(user_id: params[:user_id]) if params[:user_id].present?

    @count = query.count

    order_by = %w[id created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @stream_previews = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
  end

  def create
    if @ffmpegservice_account.sessions.ongoing.not_cancelled.not_finished.exists?
      render_json(401, 'Cannot start stream preview, a session is running') and return
    elsif @ffmpegservice_account.sessions.upcoming.not_cancelled.exists?(['start_at < ?', 5.minutes.from_now])
      render_json(401, 'Cannot start stream preview, a session is scheduled') and return
    elsif @ffmpegservice_account.stream_previews.not_finished.exists?
      render_json(401, 'Cannot start stream preview, another stream preview is in progress') and return
    end

    @stream_preview = own_organization.stream_previews.create!(
      ffmpegservice_account: @ffmpegservice_account,
      user: current_user,
      organization: own_organization
    )

    if @ffmpegservice_account.sandbox
      @ffmpegservice_account.stream_up!
    else
      client = Sender::Ffmpegservice.client(account: @ffmpegservice_account)
      client.start_stream
      if (transcoder = client.state_transcoder) && transcoder[:uptime_id].present?
        TranscoderUptime.find_or_create_by(streamable: @stream_preview, transcoder_id: @ffmpegservice_account.stream_id,
                                           uptime_id: transcoder[:uptime_id])
      end

      Sender::Ffmpegservice.client(sandbox: false).create_schedule_stop(@ffmpegservice_account.stream_id, @stream_preview.end_at)
    end

    @stop_at = @stream_preview.end_at

    FfmpegserviceAccountJobs::StreamPreviewStatus.perform_at(1.second.from_now, @stream_preview.id)
    StopFfmpegserviceStreamPreview.perform_at(@stop_at, @stream_preview.id)
    render :show
  end

  def destroy
    StopFfmpegserviceStreamPreview.new.perform(@stream_preview.id)
    @stream_preview.reload
    render :show
  end

  private

  def set_stream_preview
    @stream_preview = own_organization.stream_previews.find(params[:id])
  end

  def set_ffmpegservice_account
    @ffmpegservice_account = own_organization.ffmpegservice_accounts.find(params[:ffmpegservice_account_id])
  end
end
