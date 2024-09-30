# frozen_string_literal: true

class RecordingsController < ApplicationController
  include ControllerConcerns::ObtainingAccessToRecording
  include ControllerConcerns::TracksViews

  before_action :authenticate_user!, except: [:get_video]
  before_action :load_recording, except: [:create]

  def update
    render_json(404, 'No video found') and return if @recording.blank?
    render_json(401, 'Access denied') and return if cannot?(:edit_recording, @recording.channel)
    render_json(401, "You can't update this fields because somebody has purchased access") and return if cannot?(
      :edit_recording, @recording.channel
    ) && params[:recording].has_key?(:hide)

    respond_to do |format|
      if params[:recording][:list_id]
        if params[:recording][:list_id] == 'none'
          @recording.lists_ids = []
          params[:recording][:list_id] = nil
        else
          @recording.lists_ids = [params[:recording][:list_id]]
        end
      end
      @recording.attributes = recording_attributes

      if @recording.save
        format.json { render json: params[:recording] }
        format.html { redirect_to uploads_dashboard_path }
      else
        error = @recording.errors.full_messages.join('. ')
        format.json { render json: { error: error }, status: 422 }
        format.html { redirect_to uploads_dashboard_path, flash: { error: error } }
      end
    end
  end

  def destroy
    render_json(404, 'No video found') and return if @recording.blank?
    render_json(401, 'Access denied') and return if cannot?(:edit_recording, @recording.channel)
    render_json(401, "You can't delete this video because somebody has purchased access") and return if cannot?(
      :destroy, @recording
    )

    @recording.touch :deleted_at
    head :ok
  end

  def get_video
    render_json(404, 'No video found') and return if @recording.blank?

    if can?(:see_recording, @recording)
      track_view(@recording)
      render json: { video_url: @recording.url }
    else
      render_json(401)
    end
  end

  def toggle_wishlist_item
    @recording = Recording.find(params[:id])

    authorize!(:have_in_wishlist, @recording)

    if current_user.has_in_wishlist?(@recording)
      current_user.remove_from_wishlist(@recording)
      @has_in_wishlist_now = false
    else
      current_user.add_to_wishlist(@recording)
      @has_in_wishlist_now = true
    end

    respond_to(&:js)
  end

  private

  def load_recording
    @recording = Recording.find_by(id: params[:id])
  end

  def recordings_attributes
    recordings = params[:recordings]
    recordings.delete_if { |r| @channel.recordings.exists?(vid: r[:id], provider: 'google') }
    recordings.map do |r|
      {
        provider: 'google',
        vid: r[:id],
        title: r[:name],
        description: r[:description],
        raw: r.to_json
      }
    end
  end

  def recording_attributes
    params.require(:recording).permit(
      :title,
      :hide,
      :file,
      :purchase_price
    )
  end
end
