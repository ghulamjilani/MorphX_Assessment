# frozen_string_literal: true

json.extract! poll, :id, :question, :hidden_results, :model_id, :model_type, :created_at, :enabled,
              :duration, :manual_stop, :start_at, :end_at, :multiselect, :poll_template_id
json.is_voted poll.is_voted?(current_user&.id)
json.votes_count poll.uniq_votes
json.options do
  json.array! poll.options.order(position: :asc) do |option|
    json.extract! option, :id, :title, :position
    json.is_voted option.is_voted?(current_user&.id)
    if poll.hidden_results? && poll.enabled?
      json.votes_count 0
    else
      json.votes_count option.votes_count
    end
  end
end
json.poll_template do
  json.extract! poll.poll_template, :id, :name
end
json.model do
  case poll.model_type
  when 'Session'
    json.title poll.model.title
    json.image_url poll.model.small_cover_url
    json.url poll.model.absolute_path
    json.channel do
      json.title poll.model.channel.title
      json.image_url poll.model.channel.image_url
      json.url poll.model.channel.absolute_path
    end
    json.user do
      json.name poll.model.organizer.public_display_name
      json.image_url poll.model.organizer.avatar_url
      json.url poll.model.organizer.absolute_path
    end
  when 'Video'
    json.title poll.model.title
    json.image_url poll.model.poster_url
    json.url poll.model.absolute_path
    json.channel do
      json.title poll.model.channel.title
      json.image_url poll.model.channel.image_url
      json.url poll.model.channel.absolute_path
    end
    json.user do
      json.name poll.model.channel.organizer.public_display_name
      json.image_url poll.channel.model.organizer.avatar_url
      json.url poll.model.channel.organizer.absolute_path
    end
  when 'Recording'
    json.title poll.model.title
    json.image_url poll.model.poster_url
    json.url poll.model.absolute_path
    json.channel do
      json.title poll.model.channel.title
      json.image_url poll.model.channel.image_url
      json.url poll.model.channel.absolute_path
    end
    json.user do
      json.name poll.model.organizer.public_display_name
      json.image_url poll.model.organizer.avatar_url
      json.url poll.model.organizer.absolute_path
    end
  when 'Channel'
    json.title poll.model.title
    json.image_url poll.model.image_url
    json.url poll.model.absolute_path
    json.user do
      json.name poll.model.organizer.public_display_name
      json.image_url poll.model.organizer.avatar_url
      json.url poll.model.organizer.absolute_path
    end
  end
end
