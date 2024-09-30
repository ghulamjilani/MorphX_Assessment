# frozen_string_literal: true

json.extract! ffmpegservice_account, :id, :organization_id, :user_id, :current_service,
              :stream_id, :name, :custom_name, :delivery_method,
              :transcoder_type, :created_at, :updated_at
