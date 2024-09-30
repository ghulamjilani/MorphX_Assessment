# frozen_string_literal: true

class Api::System::StorageController < Api::System::ApplicationController
  before_action { http_basic_authenticate 'fsd3rf2de3', 'ds342df234' }

  def qencode_recording_url
    recording = Recording.where(status: %i[ready_to_tr transcoding]).find(params[:recording_id])

    redirect_to url_for(recording.file)
  end
end
