# frozen_string_literal: true

json.array! @templates, partial: 'api/v1/user/poll/poll_templates/poll_template', as: :template
