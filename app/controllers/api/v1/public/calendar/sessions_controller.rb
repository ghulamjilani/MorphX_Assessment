# frozen_string_literal: true

class Api::V1::Public::Calendar::SessionsController < Api::V1::Public::Calendar::ApplicationController
  def index
    query = Session.is_public.not_fake.published.not_archived.not_cancelled

    query = query.where('start_at >= ?', params[:start_at_from]) if params[:start_at_from].present?
    query = query.where('start_at <= ?', params[:start_at_to]) if params[:start_at_to].present?

    if params[:end_at_from].present?
      query = query.where("(start_at + (INTERVAL '1 minute' * duration)) >= ?",
                          params[:end_at_from])
    end
    if params[:end_at_to].present?
      query = query.where("(start_at + (INTERVAL '1 minute' * duration)) <= ?",
                          params[:end_at_to])
    end

    query = query.where(channel_id: params[:channel_id]) if params[:channel_id].present?

    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'

    @sessions = query.order("start_at #{order}").limit(@limit).offset(@offset)
                     .preload(
                       presenter: { user: [:image] }
                     )
  end
end
