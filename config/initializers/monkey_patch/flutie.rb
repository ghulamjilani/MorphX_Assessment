# frozen_string_literal: true

module Flutie
  class PageTitle
    def rails_app_name
      Rails.application.credentials.global[:service_name]
    end
  end
end
