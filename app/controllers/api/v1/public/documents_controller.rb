# frozen_string_literal: true

class Api::V1::Public::DocumentsController < Api::V1::Public::ApplicationController
  # GET api/v1/public/documents
  def index
    @documents = Document.not_archived.visible.includes_file
                         .joins(:channel).where(channels: { show_documents: true })
    @documents = @documents.where(channel_id: params[:channel_id]) if params[:channel_id]
    @count = @documents.count
    @documents = @documents.order(created_at: :desc)
                           .limit(@limit)
                           .offset(@offset)
  end

  # GET api/v1/public/documents/:id
  def show
    @document = Document.find(params[:id])
    authorize! :show, @document
  end

  private

  def current_ability
    @current_ability ||= AbilityLib::DocumentAbility.new(nil)
  end
end
