# frozen_string_literal: true

class Api::RecordingsController < Api::ApplicationController
  before_action :load_recording, only: [:confirm_purchase]
  before_action :sanitize_purchase_type, only: [:confirm_purchase]

  # curl -XGET http://localhost:3000/api_portal/channels/1/recordings/ -H 'X-User-Token: 9f3f5ab404dde17472119127b52aeadb1' -H 'X-User-ID:1'
  def index
    @channel = Channel.find(params[:channel_id])
    @limit = (params[:limit] || 5).to_i
    @offset = (params[:offset] || 0).to_i
    @recordings = @channel.recordings.available.visible.limit(@limit).offset(@offset)
    @recordings_count = @channel.recordings.available.visible.count
    @total_pages = (@recordings_count + @limit - 1) / @limit
    @current_page = (@offset + @limit) / @limit
  rescue StandardError => e
    render_json(500, e.message, e)
  end

  def confirm_purchase
    case @type
    when ObtainTypes::PAID_RECORDING
      interactor = ObtainAccessToRecording.new(@recording, current_user)
    when ObtainTypes::FREE_RECORDING
      interactor = ObtainAccessToRecording.new(@recording, current_user)
      interactor.free_type_is_chosen!
    else
      raise 'unknown type'
    end
    interactor.execute(params[:payment_method_nonce])
    if interactor.success_message
      render_json(200, interactor.success_message)
      Rails.logger.info "user has obtained #{@type} access to recording #{@recording.always_present_title}"
    else
      render_json(401, interactor.error_message.html_safe)
    end
  rescue StandardError => e
    render_json(500, e.message, e)
  end

  private

  def load_recording
    @recording = recording.find_by(id: params[:id])
  end

  def sanitize_purchase_type
    @type = params[:type]
    render_json(404, 'Purchase attempt failed. Please try again.') if @type.blank? || ObtainTypes::ALL.exclude?(@type)
  end
end
