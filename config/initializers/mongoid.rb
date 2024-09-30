# frozen_string_literal: true

Rails.application.config.to_prepare do
  Mongoid.raise_not_found_error = false
  begin
    Reports::V1::RevenueOrganization.create_indexes
  rescue StandardError => e
    Rails.logger.info e.message
    puts e.message
  end
end
