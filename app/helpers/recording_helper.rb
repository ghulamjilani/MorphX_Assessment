# frozen_string_literal: true

module RecordingHelper
  def recording_data_attributes(recording)
    data = {}
    data['url'] = can?(:see_recording, recording) ? recording.url : recording.preview_url

    data['id'] = recording.id
    data['title'] = recording.title
    data['thumbnail_url'] = recording.poster_url
    data['description'] = recording.description

    data['lists'] = [recording.list].to_json

    unless can?(:see_recording, recording)
      data['obtainable_for_amount'] = as_currency(recording.purchase_price)
      data['obtain_url'] = preview_purchase_recording_path(recording, type: ObtainTypes::PAID_RECORDING)
    end

    data
  end

  def recording_dashboard_attributes(recording)
    date_format = begin
      current_user.am_format? ? '%^b %d %Y, %l:%M %p' : '%^b %d %Y, %k:%M'
    rescue StandardError
      '%^b %d %Y, %l:%M %p'
    end
    data = recording.as_json
    data[:date] = begin
      recording.created_at.strftime(date_format)
    rescue StandardError
      ''
    end
    data[:duration] = begin
      distance_of_time_in_words(JSON.parse(recording.raw)['duration'])
    rescue StandardError
      0
    end
    data[:is_owner] = recording.organizer == current_user
    data[:relative_path] = recording.relative_path
    data
  end
end
