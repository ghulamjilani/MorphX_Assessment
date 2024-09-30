# frozen_string_literal: true

json.extract!   organization, :id, :name, :description, :logo_url, :relative_path, :multiroom_status, :user_id, :enable_free_subscriptions
json.logo_link  organization.logo_link(current_user)
