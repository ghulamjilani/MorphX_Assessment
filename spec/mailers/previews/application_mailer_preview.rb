# frozen_string_literal: true

class ApplicationMailerPreview < ActionMailer::Preview
  private

  def fallback_mail(error)
    Mail.new do
      to 'error@morphx.io'
      from 'noreply@morphx.io'
      # rubocop:disable RSpec/VariableDefinition
      # rubocop:disable RSpec/VariableName
      subject 'Error during mail preview'
      # rubocop:enable RSpec/VariableName
      # rubocop:enable RSpec/VariableDefinition
      text_part do
        body error.message
      end
      html_part do
        content_type 'text/html; charset=UTF-8'
        body "<h2>#{error.message}</h2>"
      end
    end
  end
end
