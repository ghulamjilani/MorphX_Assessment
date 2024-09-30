# frozen_string_literal: true

module Api
  module V1
    module User
      class InteractiveAccessTokensController < Api::V1::User::ApplicationController
        before_action :interactive_access_token, except: %i[index create]

        def index
          @session = Session.find(params[:session_id])

          query = if @session.organization.user == current_user || @session.presenter.user == current_user || can?(
            :create_session, @session.channel
          ) || can?(:start, @session)
                    # policy_scope(@session.interactive_access_tokens)
                    @session.interactive_access_tokens
                  else
                    InteractiveAccessToken.none
                  end

          if params[:individual].present?
            query = query.individual
          elsif params[:shared].present?
            query = query.shared
          end

          @count = query.count
          order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
          @interactive_access_tokens = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
        end

        def show
        end

        def create
          @interactive_access_token = InteractiveAccessToken.new(create_token_params)

          authorize @interactive_access_token

          return render_json(422, @interactive_access_token) unless @interactive_access_token.save

          render :show
        end

        def update
          return render_json(422, interactive_access_token) unless interactive_access_token.refresh_token!

          render :show
        end

        def destroy
          return render_json(422, interactive_access_token) unless interactive_access_token.destroy

          render :show
        end

        private

        def interactive_access_token
          @interactive_access_token ||= InteractiveAccessToken.find(params[:id])

          authorize @interactive_access_token, :show?

          @interactive_access_token
        end

        def create_token_params
          params.permit(:session_id, :individual)
        end
      end
    end
  end
end
