# frozen_string_literal: true

json.extract! template, :id, :name, :question, :created_at
json.polls_count template.polls.count
json.votes_count template.uniq_votes
json.options do
  json.array! template.options do |option|
    json.extract! option, :id, :title, :position
  end
end
json.organization do
  json.partial! 'api/v1/user/organizations/organization_short', organization: template.organization
end
json.user do
  json.partial! 'api/v1/user/users/user_short', user: template.user
end
