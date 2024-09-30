# frozen_string_literal: true

class Dashboard::ChannelsController < Dashboard::ApplicationController
  skip_before_action :check_if_has_needed_cookie

  skip_before_action :extract_refc_from_url_into_cookie
  skip_before_action :check_if_referral_user, if: :user_signed_in?
  skip_before_action :persist_timezone_if_not_yet_specified
  skip_before_action :set_timezone

  def sessions
    @type = params[:type]
    @limit = params[:limit].to_i.positive? ? params[:limit].to_i : 6
    @offset = params[:offset].to_i
    @channel = Channel.find(params[:id])
    order = params[:order]
    # query = PgSearchDocument.joins(:session).where(searchable_type: 'Session', channel_id: @channel.id)
    query = Session.where(channel_id: @channel.id)

    if params[:start_at_from].present? || params[:start_at_to].present?
      from = begin
        DateTime.strptime(params[:start_at_from], '%m/%d/%Y')
      rescue StandardError
        nil
      end
      to = begin
        DateTime.strptime(params[:start_at_to], '%m/%d/%Y')
      rescue StandardError
        nil
      end
      if from.present? && to.present?
        query = query.where(sessions: { start_at: from..to.end_of_day })
      elsif from.present?
        query = query.where('sessions.start_at >= :from', from: from)
      elsif to.present?
        query = query.where('sessions.start_at <= :to', to: to.end_of_day)
      end
    end

    # query = query.search_by_title(params[:title]) if params[:title].present?
    query = query.where('sessions.title ILIKE :title', title: "%#{params[:title]}%") if params[:title].present?

    case @type
    when 'all'
      @total = query.count
      order ||= :desc
    when 'upcoming'
      query = query.where("now() < (sessions.start_at + (INTERVAL '1 minute' * sessions.duration))")
                   .where("now() < (sessions.start_at + (INTERVAL '1 minute' * sessions.duration)) AND sessions.stopped_at IS NULL")
                   .where(sessions: { cancelled_at: nil })
      order ||= :asc
      @total = query.count
    when 'cancelled'
      query = query.where.not(sessions: { cancelled_at: nil })
      @total = query.count
      order ||= :desc
    when 'past'
      query = query.where("now() > (sessions.start_at + (INTERVAL '1 minute' * sessions.duration)) OR sessions.stopped_at IS NOT NULL")
      order ||= :desc
      @total = query.count
    else
      @total = query.count
    end

    # @sessions = query.preload(session: [:presenter, room: :abstract_session]).limit(@limit).offset(@offset).reorder(start_at: order)
    @sessions = query.preload(:presenter,
                              room: :abstract_session).limit(@limit).offset(@offset).reorder(start_at: order)
    respond_to :js
  end
end
