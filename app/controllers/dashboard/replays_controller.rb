# frozen_string_literal: true

class Dashboard::ReplaysController < Dashboard::ApplicationController
  def index
    respond_to do |format|
      format.json do
        channel = current_user.current_organization&.channels&.find(params[:id])
        filters = get_default_pg_filters
        @limit = (params[:limit].to_i.zero? ? 10 : params[:limit].to_i)
        @offset = params[:offset].to_i

        replays = Video.allowed_user_statuses.joins(:room)
                       .joins(%(INNER JOIN sessions ON rooms.abstract_session_id = sessions.id AND rooms.abstract_session_type = 'Session'))
                       .where(videos: { deleted_at: nil }, sessions: { channel_id: channel.id })
                       .where.not(sessions: { recorded_purchase_price: nil })
        # apply filters
        replays = replays.where(sessions: { recorded_free: filters[:free] }) if filters[:free].present?
        replays = replays.where(videos: { show_on_profile: filters[:visible] }) if filters[:visible].present?
        if filters[:published].present?
          if filters[:published].include?(false) && filters[:published].include?(true)
            # do nothing
          elsif filters[:published].include?(false)
            replays = replays.where(videos: { published: nil })
          elsif filters[:published].include?(true)
            replays = replays.where.not(videos: { published: nil })
          end
        end
        if filters[:start_at].present?
          if filters[:start_at][:from].present? && filters[:start_at][:to].present?
            replays = replays.where(sessions: { start_at: filters[:start_at][:from]..filters[:start_at][:to] })
          elsif filters[:start_at][:from].present?
            replays = replays.where('sessions.start_at >= ?', filters[:start_at][:from])
          elsif filters[:start_at][:to].present?
            replays = replays.where('sessions.start_at <= ?', filters[:start_at][:to])
          end
        end
        replays = replays.search_by_name(filters[:query]) if filters[:query].present?
        order = %w[asc desc].include?(filters[:sort]) ? filters[:sort] : 'desc'
        @total = replays.count
        @replays = replays.reorder("sessions.start_at #{order}").limit(@limit).offset(@offset)
      end
    end
  end

  def update
    replay = Video.find(params[:id])
    render_json(404, 'No video found') and return if replay.blank?
    render_json(401, 'Access denied') and return if cannot?(:edit_replay, replay.channel)

    attributes = params.permit(:title, :description, :show_on_profile, :only_ppv, :only_subscription).tap do |p|
      p[:session_attributes] = {}
      if params.has_key?(:price)
        p[:session_attributes][:recorded_purchase_price] = params[:price].to_f
        p[:session_attributes][:recorded_free] = params[:price].to_f.zero?
      end
      p[:session_attributes][:allow_chat] = params[:allow_chat] if params.has_key?(:allow_chat)
      p[:session_attributes][:private] = false if params.has_key?(:private) && !params[:private]
      if params.has_key?(:list_id)
        if params[:list_id].blank?
          p[:attached_list_ids] = []
        else
          p[:attached_lists_attributes] = [{ list_id: params[:list_id] }]
        end
      end
      p[:session_attributes].permit!
    end
    replay.update!(attributes)
  end

  def save_image
    replay = Video.find(params[:id])

    render_json(404, 'No video found') and return if replay.blank?
    render_json(401, 'Access denied') and return if cannot?(:edit_replay, replay.channel)

    if params[:video_image_attributes]
      attributes = if params[:video_image_attributes][:source_type].to_i.zero?
                     params.permit(video_image_attributes: %i[crop_x crop_y crop_w crop_h rotate image source_type])
                   elsif params[:video_image_attributes][:source_type].to_i == 1
                     params.permit(video_image_attributes: %i[frame_position image source_type]).tap do |a|
                       filename = "frame_thumbnail_#{a[:video_image_attributes][:frame_position]}_#{replay.id}.png"
                       base64_data = params[:video_image_attributes][:remote_image_url]

                       start_regex = %r{data:image/[a-z]{3,4};base64,}
                       regex_result = start_regex.match(base64_data)
                       start = regex_result.to_s

                       tempfile = Tempfile.new(filename)
                       tempfile.binmode
                       tempfile.write(Base64.decode64(base64_data[start.length..]))

                       uploaded_file = ActionDispatch::Http::UploadedFile.new(
                         tempfile: tempfile,
                         filename: filename,
                         original_filename: filename,
                         type: 'image/png',
                         head: "Content-Disposition: form-data; name=\"video_image_attributes[image]\"; filename=\"#{filename}\"\nContent-Type: image/png"
                       )
                       a[:video_image_attributes][:image] = uploaded_file
                     end
                   end
      if attributes.present?
        replay.video_image&.destroy
        replay.update!(attributes)
      end
      tempfile.delete if defined?(tempfile)
    end
  end

  def publish_toggle
    replay = Video.find(params[:id])

    render_json(404, 'No video found') and return if replay.blank?
    render_json(401, 'Access denied') and return if cannot?(:transcode_replay, replay.channel)

    unless replay.published?
      render_json(422, replay.errors.full_messages.join('. ')) and return unless replay.publish!

      attributes = params.permit(:crop_seconds, :cropped_duration)
      replay.update!(attributes)
    end
    render json: { published: replay.published? }
  end

  def destroy
    replay = Video.find(params[:id])

    render_json(404, 'No video found') and return if replay.blank?
    render_json(401, 'Access denied') and return if cannot?(:delete_replay, replay.channel)

    replay.mark_as_destroy
    render json: replay
  end

  def group_publish
    render_json(401, 'Access denied') and return if cannot?(:transcode_replay, current_user.current_organization)

    channel_ids = current_user.channels.map(&:id)
    replays = Video.joins(:channel).where(channels: { id: channel_ids }).where(id: params[:ids], published: nil)
    # At first we need to update not marked to publish and processed videos
    replays.where.not(status: %i[ready_to_tr transcoding transcoded done error]).update_all(published: Time.now, status: :ready_to_tr)
    # if selected videos contain already processed items then mark them as published
    replays.where(status: %i[ready_to_tr transcoding transcoded done]).update_all(published: Time.now)
    replays.find_each(&:update_pg_search_document)
    @replays = Video.joins(:channel).where(channels: { id: channel_ids }).where(id: params[:ids])
    render :index
  end

  def group_destroy
    render_json(401, 'Access denied') and return if cannot?(:delete_replay, current_user.current_organization)

    channel_ids = current_user.channels.map(&:id)
    replays = Video.joins(:channel).where(channels: { id: channel_ids }).where(id: params[:ids])
    replays.find_each { |r| r.touch :deleted_at }
    head :ok
  end

  def group_move
    render_json(401, 'Access denied') and return if cannot?(:edit_replay, current_user.current_organization)

    owned_channel_ids = current_user.all_channels.map(&:id)
    channel_id_to_move = owned_channel_ids.find { |c_id| c_id == params[:channel_id].to_i }
    video_ids = params[:video_ids].to_a.map(&:to_i)
    result = video_ids.each.map { |el| [el, false] }.to_h

    if channel_id_to_move.blank?
      return render(json: { result: result,
                            errors: [I18n.t('dashboard.channel.dont_have_access')] })
    end

    errors = []

    video_ids.each do |video_id|
      video = Video.find video_id
      session = Session.joins(room: :videos).joins(:channel).where(channels: { id: owned_channel_ids },
                                                                   videos: { id: video_id }).first
      if cannot?(:move_between_channels, session)
        errors.push I18n.t('dashboard.cannot_manipulate_video', video_title: video.always_present_title)
        result[video_id] = false
        next
      end
      result[video_id] = session.update_columns(channel_id: channel_id_to_move)
      session.records.find_each(&:update_pg_search_document)
    end
    render json: { result: result, errors: errors.presence }
  end

  private

  def get_default_pg_filters
    f = params[:filters] || {}
    f[:free].to_a.each_with_index do |v, i|
      f[:free][i] = (v == 't')
    end
    f[:visible].to_a.each_with_index do |v, i|
      f[:visible][i] = (v == 't')
    end
    f[:published].to_a.each_with_index do |v, i|
      f[:published][i] = (v == 't')
    end

    filters = {
      start_at: {
        from: begin
          Date.strptime(f[:start_at][:from], '%m/%d/%Y')
        rescue StandardError
          nil
        end,
        to: begin
          Date.strptime(f[:start_at][:to], '%m/%d/%Y')
        rescue StandardError
          nil
        end
      },
      free: f[:free].presence || [false, true],
      visible: f[:visible].presence || [false, true],
      published: f[:published].presence || [false, true]
    }
    filters[:sort] = f[:sort] if f[:sort].present?
    filters[:query] = f[:query] if f[:query].present?
    filters
  end
end
