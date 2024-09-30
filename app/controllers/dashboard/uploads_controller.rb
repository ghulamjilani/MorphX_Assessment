# frozen_string_literal: true

class Dashboard::UploadsController < Dashboard::ApplicationController
  def index
    respond_to do |format|
      format.json do
        channel = current_user.all_channels.find(params[:id])
        filters = get_default_filters
        @limit = (params[:limit].to_i.zero? ? 10 : params[:limit].to_i)
        @offset = params[:offset].to_i
        query = channel.recordings.not_deleted
        if filters[:created_at]
          if filters[:created_at][:from] && filters[:created_at][:to]
            query = query.where(created_at: filters[:created_at][:from]..filters[:created_at][:to])
          elsif filters[:created_at][:from]
            query = query.where('created_at >= :created_from', created_from: filters[:created_at][:from])
          elsif filters[:created_at][:to]
            query = query.where('created_at <= :created_to', created_to: filters[:created_at][:to])
          end
        end
        if filters[:free].include?(true) && filters[:free].include?(false)
          # do nothing
        elsif filters[:free].include?(false)
          query = query.where.not(purchase_price: [0, nil])
        elsif filters[:free].include?(true)
          query = query.where(purchase_price: [0, nil])
        end
        if filters[:visible].include?(true) && filters[:visible].include?(false)
          # do nothing
        elsif filters[:visible].include?(false)
          query = query.where(hide: true)
        elsif filters[:free].include?(true)
          query = query.where(hide: false)
        end
        if filters[:published].include?(true) && filters[:published].include?(false)
          # do nothing
        elsif filters[:published].include?(false)
          query = query.where(published: nil)
        elsif filters[:published].include?(true)
          query = query.where.not(published: nil)
        end
        if filters[:query].present? && filters[:query] != '*'
          query = query.search_by_name(filters[:query])
        end
        @total = query.count

        order = %w[asc desc].include?(filters[:sort]) ? filters[:sort] : 'desc'
        @recordings = query.order("created_at #{order}").limit(@limit).offset(@offset)
      end
    end
  end

  def create
    @channel = current_user.all_channels.find(params[:id])

    file = params[:recording][:file]
    recording = @channel.recordings.new
    recording.file = file[:blob]
    recording.title = file[:filename]

    respond_to do |format|
      if recording.save
        format.json { render json: { recordings: {} } }
      else
        format.json { render json: { error: recording.errors.full_messages }, status: 422 }
      end
    end
  end

  def update
    recording = Recording.find(params[:id])
    render_json(404, 'No video found') and return if recording.blank?
    render_json(401, 'Access denied') and return if cannot?(:edit_recording, recording.channel)

    attributes = params.permit(:title, :description, :hide, :purchase_price, :private, :only_ppv,
                               :only_subscription).tap do |attrs|
      if params.has_key?(:list_id)
        if params[:list_id].blank?
          attrs[:attached_list_ids] = []
        else
          attrs[:attached_lists_attributes] = [{ list_id: params[:list_id] }]
        end
      end
      attrs.permit!
    end
    recording.update!(attributes)
  end

  def save_image
    recording = Recording.find(params[:id])

    render_json(404, 'No video found') and return if recording.blank?
    render_json(401, 'Access denied') and return if cannot?(:edit_recording, recording.channel)

    if params[:recording_image_attributes]
      attributes = if params[:recording_image_attributes][:source_type].to_i.zero?
                     params.permit(recording_image_attributes: %i[crop_x crop_y crop_w crop_h rotate image source_type])
                   elsif params[:recording_image_attributes][:source_type].to_i == 1
                     params.permit(recording_image_attributes: %i[frame_position image source_type]).tap do |a|
                       filename = "frame_thumbnail_#{a[:recording_image_attributes][:frame_position]}_#{recording.id}.png"
                       base64_data = params[:recording_image_attributes][:remote_image_url]

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
                         head: "Content-Disposition: form-data; name=\"recording_image_attributes[image]\"; filename=\"#{filename}\"\nContent-Type: image/png"
                       )
                       a[:recording_image_attributes][:image] = uploaded_file
                     end
                   end
      if attributes.present?
        recording.recording_image&.destroy
        recording.update!(attributes)
      end
      tempfile.delete if defined?(tempfile)
    end
  end

  def publish
    recording = Recording.find_by(id: params[:id])

    render_json(404, 'No video found') and return if recording.blank?
    render_json(401, 'Access denied') and return if cannot?(:transcode_recording, recording.channel)

    unless recording.published?
      attributes = params.permit(:crop_seconds, :cropped_duration)
      recording.update!(attributes)
      recording.publish!
    end

    render json: { published: recording.published? }
  end

  def publish_toggle
    recording = Recording.find_by(id: params[:id])

    render_json(404, 'No video found') and return if recording.blank?
    render_json(401, 'Access denied') and return if cannot?(:transcode_recording, recording.channel)

    if recording.published?
      recording.unpublish!
    else
      attributes = params.permit(:crop_seconds, :cropped_duration)
      recording.update!(attributes)
      recording.publish!
    end
    # head :ok
    render json: { published: recording.published? }
  end

  def destroy
    recording = Recording.find(params[:id])

    render_json(404, 'No video found') and return if recording.blank?
    render_json(401, 'Access denied') and return if cannot?(:delete_recording, recording.channel)

    recording.touch :deleted_at
    # head :ok
    render json: recording
  end

  def group_publish
    render_json(401, 'Access denied') and return if cannot?(:transcode_recording, current_user.current_organization)

    channel_ids = current_user.channels.map(&:id)
    recordings = Recording.joins(:channel).where(channels: { id: channel_ids }).where(id: params[:ids], published: nil)
    # At first we need to update not marked to publish and processed videos
    recordings.where.not(status: %i[ready_to_tr transcoding transcoded done error])
              .update_all(published: Time.now, status: :ready_to_tr,
                          updated_at: Time.now)
    # if selected videos contain already processed items then mark them as published
    recordings.where(status: %i[ready_to_tr transcoding transcoded done]).update_all(published: Time.now, updated_at: Time.now)
    @recordings = Recording.joins(:channel).where(channels: { id: channel_ids }).where(id: params[:ids])
    render :index
  end

  def group_destroy
    render_json(401, 'Access denied') and return if cannot?(:delete_recording, current_user.current_organization)

    channel_ids = current_user.channels.map(&:id)
    recordings = Recording.joins(:channel).where(channels: { id: channel_ids }).where(id: params[:ids])

    recordings.find_each { |r| r.touch :deleted_at }
    head :ok
  end

  def group_move
    render_json(401, 'Access denied') and return if cannot?(:edit_recording, current_user.current_organization)

    owned_channel_ids = current_user.all_channels.map(&:id)
    channel_id_to_move = owned_channel_ids.find { |c_id| c_id == params[:channel_id].to_i }
    video_ids = params[:video_ids].to_a.map(&:to_i)
    result = video_ids.each.map { |el| [el, false] }.to_h

    if channel_id_to_move.blank?
      return render(json: { result: result,
                            errors: [I18n.t('dashboard.channel.dont_have_access')] })
    end

    errors = []

    recordings = Recording.joins(:channel).where(channels: { id: owned_channel_ids },
                                                 recordings: { id: params[:video_ids] })
    recordings.find_each do |recording|
      if cannot?(:edit_recording, recording.channel)
        errors.push I18n.t('dashboard.cannot_manipulate_video', video_title: recording.always_present_title)
        next
      end
      result[recording.id.to_s] = recording.update(channel_id: channel_id_to_move)
    end

    render json: { result: result, errors: errors.presence }
  end

  private

  def current_ability
    @current_ability ||= ::AbilityLib::ChannelAbility.new(current_user).merge(::AbilityLib::OrganizationAbility.new(current_user))
  end

  def get_default_filters
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
    from = begin
      Date.strptime(f[:created_at][:from], '%m/%d/%Y')
    rescue StandardError
      nil
    end
    to = begin
      Date.strptime(f[:created_at][:to], '%m/%d/%Y')
    rescue StandardError
      nil
    end
    {
      sort: f[:sort] || '*',
      query: f[:query] || '*',
      created_at: {
        from: from,
        to: to
      },
      free: f[:free].presence || [false, true],
      visible: f[:visible].presence || [false, true],
      published: f[:published].presence || [false, true]
    }
  end
end
