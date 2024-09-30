# frozen_string_literal: true

class Api::System::FfmpegserviceAccountsController < Api::System::ApplicationController
  before_action :http_basic_authenticate
  before_action :load_ffmpegservice_account, only: [:update_stream_status]

  def update_stream_status
    @ffmpegservice_account&.stream_status_changed
    head :ok
  end

  private

  def load_ffmpegservice_account
    @ffmpegservice_account = FfmpegserviceAccount.find_by(id: params[:id])
  end
end
