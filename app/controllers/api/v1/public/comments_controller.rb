# frozen_string_literal: true

module Api
  module V1
    module Public
      class CommentsController < Api::V1::Public::ApplicationController
        def index
          query = commentable.comments.visible
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
          @count = query.count
          @comments = query.order(Arel.sql("created_at #{order}")).limit(@limit).offset(@offset).preload(%i[user
                                                                                                            commentable])
        end

        private

        def commentable
          @commentable ||= begin
            commentable = params.require(:commentable_type).classify.constantize.find(params.require(:commentable_id))
            commentable = commentable.session if commentable.is_a?(Video)
            unless commentable.respond_to?(:comments)
              raise(ArgumentError,
                    I18n.t('controllers.api.v1.public.comments.errors.unsupported_type',
                           commentable_type: commentable.class.to_s))
            end
            if current_ability.cannot?(
              :read, commentable
            )
              raise(ArgumentError,
                    I18n.t('controllers.api.v1.public.comments.errors.read_forbidden',
                           commentable_type: commentable.class.to_s))
            end

            commentable
          end
        end

        def current_ability
          @current_ability ||= channel_ability
                               .merge(organization_ability)
                               .merge(session_ability)
                               .merge(recording_ability)
                               .merge(comment_ability)
        end
      end
    end
  end
end
