# frozen_string_literal: true

module Api
  module V1
    module User
      module PageBuilder
        class ModelTemplatesController < Api::V1::User::PageBuilder::ApplicationController
          before_action :model_template, only: %i[destroy]

          def index
            raise AccessForbiddenError unless current_ability.can?(:list_page_builder_templates, organization)

            query = ::PageBuilder::SystemTemplate.where(organization_id: organization.id)
            query = query.where(model_type: params[:model_type], model_id: params[:model_id]) if params[:model_type].present? && params[:model_id].present?

            @count = query.count
            order_by = if %w[name created_at].include?(params[:order_by])
                         params[:order_by]
                       else
                         'name'
                       end
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
            @system_templates = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
          end

          def show
            @model_template = ::PageBuilder::ModelTemplate.find_by!(model_type: params.require(:model_type), model_id: params.require(:model_id))
            @template_cache_key = ::PageBuilder::ModelTemplate.template_cache_key(type: params[:model_type], id: params[:model_id])
          end

          def create
            raise AccessForbiddenError unless current_ability.can?(:moderate_page_builder_template, model)

            @model_template = ::PageBuilder::ModelTemplate.find_or_initialize_by!(model: model)
            @model_template.body = params.require(:body)
            @model_template.save!
            render :show
          end

          def destroy
            raise AccessForbiddenError unless current_ability.can?(:moderate_page_builder_template, model)

            @model_template.destroy!
            render :show
          end

          private

          def model
            @model ||= params.require(:model_type).classify.constantize.find(params.require(:model_id))
          end

          def model_template
            @model_template ||= ::PageBuilder::ModelTemplate.find_by!(model_type: params.require(:model_type), model_id: params.require(:model_id))
          end

          def organization
            @organization ||= Organization.find(params.require(:organization))
          end

          def current_ability
            @current_ability ||= organization_ability
                                 .merge(channel_ability)
                                 .merge(user_ability)
          end
        end
      end
    end
  end
end
