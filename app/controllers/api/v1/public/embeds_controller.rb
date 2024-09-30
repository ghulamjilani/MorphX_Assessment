# frozen_string_literal: true

class Api::V1::Public::EmbedsController < Api::V1::Public::ApplicationController
  # GET /api/v1/public/recordings/:recording_id/embeds
  # GET /api/v1/public/videos/:video_id/embeds
  # GET /api/v1/public/sessions/:session_id/embeds
  def index
    @shared_model = if params[:recording_id]
                      Recording.find(params[:recording_id])
                    elsif params[:video_id]
                      Video.find(params[:video_id])
                    elsif params[:session_id]
                      Session.find(params[:session_id])
                    end

    render_json 404 and return unless @shared_model
  end
end
