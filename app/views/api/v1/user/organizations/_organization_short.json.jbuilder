# frozen_string_literal: true

json.extract!   organization, :id, :name, :logo_url, :relative_path, :user_id, :enable_free_subscriptions
json.logo_link  organization.logo_link(current_user)
