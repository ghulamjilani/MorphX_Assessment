# frozen_string_literal: true

module Api
  module V1
    module User
      module PageBuilder
        class SystemTemplatesController < Api::V1::User::PageBuilder::ApplicationController
          before_action :system_template, only: %i[show destroy]

          def index
            raise AccessForbiddenError unless current_ability.can?(:create, ::PageBuilder::SystemTemplate)

            query = ::PageBuilder::SystemTemplate
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
          end

          def create
            raise AccessForbiddenError unless current_ability.can?(:create, ::PageBuilder::SystemTemplate)

            @system_template = ::PageBuilder::SystemTemplate.find_or_initialize_by(name: params.require(:name))
            @system_template.body = params.require(:body)
            @system_template.save!
            render :show
          end

          def destroy
            raise AccessForbiddenError unless current_ability.can?(:create, ::PageBuilder::SystemTemplate)

            @system_template.destroy!
            render :show
          end

          private

          def system_template
            @system_template ||= ::PageBuilder::SystemTemplate.find_by!(name: params.require(:name))
          end

          def current_ability
            @current_ability ||= AbilityLib::PageBuilder::SystemTemplateAbility.new(current_user)
          end
        end
      end
    end
  end
end
