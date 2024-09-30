# frozen_string_literal: true

class Api::V1::Blog::LinkPreviewsController < Api::V1::Blog::ApplicationController
  skip_before_action :authorization_only_for_user, only: %i[index show]

  def index
    query = if params[:resource_id].present?
              params.require(:resource_type).classify.constantize.visible_for_user(current_user).find(params[:resource_id]).link_previews
            elsif params[:resource_type] == 'Blog::Post' && params[:resource_slug].present?
              Blog::Post.visible_for_user(current_user).friendly.find(params[:resource_slug]).link_previews
            else
              render_json(422, 'Unprocessible resource') and return
            end

    @count = query.link_previews.count
    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'updated_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @link_previews = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
    @link_preview = LinkPreview.find(params[:id])
  end

  def create
    @link_preview = LinkPreview.create_or_find_by!(url: SanitizeUrl.sanitize_url(params.require(:url)))
    if @link_preview.status_error? || @link_preview.outdated?
      @link_preview.status_new!
      @link_preview.schedule_link_parse
    end
    render :show
  end

  def parse
    @link_preview = LinkPreview.find(params[:id])
    LinkPreviewJobs::ParseJob.new.perform(@link_preview.id)
    @link_preview.reload
    render :show
  end
end
