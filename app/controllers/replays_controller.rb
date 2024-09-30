# frozen_string_literal: true

require 'net/https'

class ReplaysController < ApplicationController
  before_action :authenticate_user!
  before_action :load_replay, except: :update_session

  def update
    render_json(404, 'No video found') and return if @replay.blank?
    render_json(401, 'Access denied') and return if cannot?(:edit_replay, @replay.channel)
    render_json(401, "You can't update this fields because somebody has purchased access") and return if cannot?(
      :edit_replay, @replay.channel
    ) && params[:replay].has_key?(:show_on_profile)

    respond_to do |format|
      @replay.attributes = replay_attributes
      if @replay.save
        format.json { render json: params[:replay] }
        format.html { redirect_to replays_dashboard_path }
      else
        error = @replay.errors.full_messages.join('. ')
        format.json { render json: { error: error }, status: 422 }
        format.html { redirect_to replays_dashboard_path, flash: { error: error } }
      end
    end
  end

  def update_session
    @session = Session.find_by(id: params[:id])
    render_json(404, 'No session found') and return if @session.blank?
    render_json(401, 'Access denied') and return if cannot?(:edit, @session)

    respond_to do |format|
      if params[:session] && params[:session][:title]
        @session.records.update_all(title: params[:session][:title])
        format.json { render json: params[:session] }
        format.html { redirect_to replays_dashboard_path }
      else
        @session.attributes = session_attributes
        if @session.save
          format.json { render json: params[:session] }
          format.html { redirect_to replays_dashboard_path }
        else
          error = @session.errors.full_messages.join('. ')
          format.json { render json: { error: error }, status: 422 }
          format.html { redirect_to replays_dashboard_path, flash: { error: error } }
        end
      end
    end
  end

  def destroy
    render_json(404, 'No video found') and return if @replay.blank?
    render_json(401, 'Access denied') and return if cannot?(:edit_replay, @replay.channel)
    render_json(401, "You can't delete this video because somebody has purchased access") and return if cannot?(
      :destroy, @replay
    )

    @replay.mark_as_destroy
    respond_to do |format|
      format.json { render json: params[:id] }
      format.html { redirect_to replays_dashboard_path }
    end
  end

  private

  def load_replay
    @replay = Video.find_by(id: params[:id])
  end

  def replay_attributes
    params.require(:replay).permit(:show_on_profile)
  end

  def session_attributes
    params.require(:session).permit(:private, :recorded_purchase_price, :recorded_free).tap do |p|
      p[:recorded_free] = p[:recorded_purchase_price].to_f.zero? if p.has_key?(:recorded_purchase_price)
      p[:private] = false if p.has_key?(:private)
    end
  end
end
