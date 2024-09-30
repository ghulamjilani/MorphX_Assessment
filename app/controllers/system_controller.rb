# frozen_string_literal: true

class SystemController < ActionController::Base
  def go
    go_creds = Rails.application.credentials.backend[:go]
    if params[:service] == go_creds[:service]
      cookies[go_creds[:cookie_key]] = {
        value: '1',
        expires: 1.year.from_now
      }
    end
    redirect_to root_path
  end

  def server_time
    render json: (Time.now.to_f * 1000).round
  end
end
