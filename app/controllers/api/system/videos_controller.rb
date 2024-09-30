# frozen_string_literal: true

class Api::System::VideosController < Api::System::ApplicationController
  before_action :http_basic_authenticate
  before_action :load_video, only: [:update_pg_search_document]

  def update_pg_search_document
    @video.update_pg_search_document
    head :ok
  end

  private

  def load_video
    @video = Video.find params[:id]
  end
end
