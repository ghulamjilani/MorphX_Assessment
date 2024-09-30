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
