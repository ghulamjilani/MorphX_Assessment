# frozen_string_literal: true

json.array! @polls, partial: 'api/v1/user/poll/polls/poll', as: :poll
