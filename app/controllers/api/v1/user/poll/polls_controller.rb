# frozen_string_literal: true

module Api
  module V1
    module User
      module Poll
        class PollsController < Api::V1::User::Poll::ApplicationController
          before_action :set_poll, only: %i[show update destroy]

          def index
            @polls = begin
              current_user.current_organization.poll_templates.find(params[:poll_template_id]).polls.order(created_at: :desc)
            rescue StandardError
              []
            end
          end

          def show
          end

          def create
            template = current_user.current_organization.poll_templates.find(params[:poll_template_id])
            @poll = template.polls.new(poll_params)
            @poll.question = template.question
            @poll.options_attributes = template.options.map { |o| { title: o.title, position: o.position } }
            if @poll.save
              @poll.start!
              render :show, status: :created
            else
              render json: { message: @poll.errors.full_messages.join('. ') }, status: :unprocessable_entity
            end
          end

          def update
            if params[:poll][:enabled]
              @poll.start!
            else
              @poll.stop!
            end

            render :show, status: :ok
          rescue StandardError => e
            render json: e.message, status: :unprocessable_entity
          end

          def destroy
            @poll.stop!
            @poll.destroy

            head :no_content
          end

          def vote
            @poll = ::Poll::Template::Poll.find(params[:poll_template_id]).polls.find(params[:poll_id])
            @poll.vote!(current_user, params[:option_ids])

            render :show, status: :ok
          end

          private

          def set_poll
            @poll = current_user.current_organization.poll_templates.find(params[:poll_template_id]).polls.find(params[:id])
          end

          def poll_params
            params.require(:poll).permit(:model_id, :model_type, :duration, :manual_stop, :multiselect, :hidden_results)
          end
        end
      end
    end
  end
end
