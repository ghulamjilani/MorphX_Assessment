# frozen_string_literal: true

json.models do
  json.array! @recordings do |recording|
    json.extract! recording, :id, :channel_id, :title, :description, :hide,
                  :private, :status, :published, :purchase_price, :only_ppv, :only_subscription, :blocked, :block_reason
    json.duration recording.actual_duration
    json.presenter_name recording.organizer&.public_display_name
    json.views_count recording.views_count
    json.created_at recording.created_at.to_fs(:rfc3339)
    json.poster_url recording.poster_url
    json.original_url recording.url
    begin
      # json.blob_file_path rails_blob_url(recording.file)
      json.blob_file_path recording.file.url
    rescue StandardError
      json.blob_file_path nil
    end
    json.done recording.status == 'done'
    json.processing recording.processing?
    json.rating recording.rating
    json.creator_revenue recording.organizer.revenue_percent
    json.immerss_revenue 100 - recording.organizer.revenue_percent
    json.list_id recording.lists.first&.id

    json.frame_position recording.recording_image&.frame_position || 0
    json.source_type recording.recording_image&.source_type || 0
    if recording.recording_image
      if recording.recording_image&.source_type&.zero?
        json.uploaded_poster_url recording.recording_image&.image&.url
      elsif recording.recording_image&.source_type == 1
        json.uploaded_poster_url recording.poster_url
        json.timeline_poster_url recording.recording_image&.image&.url
      end
    else
      json.uploaded_poster_url recording.poster_url
    end
    json.absolute_url recording.absolute_path
  end
end
json.limit @limit
json.offset @offset
json.total @total
