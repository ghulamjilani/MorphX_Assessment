# frozen_string_literal: true

class Api::System::RecordingsController < Api::System::ApplicationController
  before_action :http_basic_authenticate
  before_action :load_recording, only: [:update_pg_search_document]

  def update_pg_search_document
    @recording.update_pg_search_document
    head :ok
  end

  private

  def load_recording
    @recording = Recording.find params[:id]
  end
end
