# frozen_string_literal: true

module Api
  module V1
    module User
      module Poll
        class PollTemplatesController < Api::V1::User::Poll::ApplicationController
          before_action :set_template, only: %i[show update destroy]

          def index
            @templates = begin
              current_user.current_organization.poll_templates.order(created_at: :desc)
            rescue StandardError
              []
            end
          end

          def show
          end

          def create
            @template = current_user.current_organization.poll_templates.new(template_params)
            if @template.save
              render :show, status: :created
            else
              render json: { message: @template.errors.full_messages.join('. ') }, status: :unprocessable_entity
            end
          end

          def update
            if @template.update(template_params)
              render :show, status: :ok
            else
              render json: @template.errors.full_messages.join('. '), status: :unprocessable_entity
            end
          end

          def destroy
            @template.destroy

            head :no_content
          end

          private

          def set_template
            @template = current_user.current_organization.poll_templates.find(params[:id])
          end

          def template_params
            params.require(:poll_template).permit(:name, :question, :user_id, options_attributes: %i[id title position _destroy]).tap do |attrs|
              attrs[:user_id] = current_user.id
            end
          end
        end
      end
    end
  end
end
