# frozen_string_literal: true

module Api
  module V1
    module Public
      module PageBuilder
        class ModelTemplatesController < Api::V1::Public::PageBuilder::ApplicationController
          def show
            @template_cache_key = ::PageBuilder::ModelTemplate.template_cache_key(type: params[:model_type], id: params[:model_id])
          end

          def model_template
            @model_template ||= ::PageBuilder::ModelTemplate.where(model_type: params.require(:model_type)).find_by!(model_id: params.require(:model_id)) || ::PageBuilder::ModelTemplate.new(model_type: params[:model_type], model_id: params[:model_id], body: {}.to_json)
          end

          helper_method :model_template
        end
      end
    end
  end
end
