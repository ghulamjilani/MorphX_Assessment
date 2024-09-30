# frozen_string_literal: true

class EmailsEnvSubjectInterceptor
  def self.delivering_email(message)
    message.subject += " [#{Rails.env.upcase}]"
  end
end
