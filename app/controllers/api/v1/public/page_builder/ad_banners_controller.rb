# frozen_string_literal: true

module Api
  module V1
    module Public
      module PageBuilder
        class AdBannersController < Api::V1::Public::PageBuilder::ApplicationController
          def index
            @ad_banner_keys = ::PageBuilder::AdBanner.active.select(:key).group(:key).pluck(:key)
          end
        end
      end
    end
  end
end
