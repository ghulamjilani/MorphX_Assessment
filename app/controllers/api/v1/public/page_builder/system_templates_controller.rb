# frozen_string_literal: true

module Api
  module V1
    module Public
      module PageBuilder
        class SystemTemplatesController < Api::V1::Public::PageBuilder::ApplicationController
          def show
            @template_cache_key = ::PageBuilder::SystemTemplate.template_cache_key(params.require(:name))
          end

          def system_template
            @system_template ||= ::PageBuilder::SystemTemplate.find_by(name: params.require(:name)) || ::PageBuilder::SystemTemplate.new(name: params.require(:name), body: {}.to_json)
          end

          helper_method :system_template
        end
      end
    end
  end
end
