# frozen_string_literal: true

module Api
  module V1
    module User
      class CommentsController < Api::V1::User::ApplicationController
        def index
          query = Comment.visible_for_user(current_user)
          if params[:commentable_id].present? && params[:commentable_type].present?
            query = case commentable.class.to_s
                    when 'Channel'
                      query.where(%(sessions.channel_id = :channel_id OR recordings.channel_id = :channel_id),
                                  channel_id: commentable.id)
                    when 'Organization'
                      query.joins('LEFT JOIN channels on sessions.channel_id = channels.id OR recordings.channel_id = channels.id')
                           .joins('LEFT JOIN organizations on channels.organization_id = organizations.id')
                           .where(organizations: { id: commentable.id })
                    else
                      query.where(commentable: commentable)
                    end
          end
          query = query.where(comments: { visible: params[:visible] }) unless params[:visible].nil?
          if params[:created_before].present? || params[:created_after].present?
            query = if params[:created_before].present? && params[:created_after].present?
                      query.where('comments.created_at BETWEEN :after AND :before', before: params[:created_before],
                                                                                    after: params[:created_after])
                    elsif params[:created_before].present?
                      query.where('comments.created_at < :before', before: params[:created_before])
                    else
                      query.where('comments.created_at > :after', after: params[:created_after])
                    end
          end
          query = query.where(user_id: params[:user_id]) if params[:user_id].present?

          @count = query.count
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
          @comments = query.order(Arel.sql("comments.id #{order}")).limit(@limit).offset(@offset).preload(%i[user
                                                                                                             commentable])
        end

        def show
          @comment = Comment.visible_for_user(current_user).find_by(id: params[:id])
          unless @comment.present? && current_ability.can?(
            :read, @comment
          )
            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.user.comments.errors.read_forbidden'))
          end
        end

        def create
          if current_ability.cannot?(
            :comment, commentable
          )
            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.user.comments.errors.create_forbidden',
                         commentable_type: commentable.class.to_s))
          end

          @comment = commentable.comments.build(create_comment_params)
          @comment.user = current_user
          @comment.save!
          render :show
        end

        def update
          @comment = Comment.find_by(id: params[:id])
          unless @comment.present? && (current_ability.can?(
            :edit, @comment
          ) || current_ability.can?(:moderate, @comment))
            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.blog.comments.errors.update_forbidden'))
          end

          @comment.update!(update_comment_params)
          render :show
        end

        def destroy
          @comment = Comment.find_by(id: params[:id])
          unless @comment.present? && current_ability.can?(
            :destroy, @comment
          )
            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.blog.comments.errors.destroy_forbidden'))
          end

          @comment.destroy!
          render :show
        end

        private

        def commentable
          @commentable ||= begin
            commentable = (params[:comment].present? ? params[:comment].require(:commentable_type) : params.require(:commentable_type))
                          .classify.constantize.find((params[:comment].present? ? params[:comment].require(:commentable_id) : params.require(:commentable_id)))
            commentable = commentable.session if commentable.is_a?(Video)
            unless commentable.respond_to?(:comments)
              raise(ArgumentError,
                    I18n.t('controllers.api.v1.public.comments.errors.unsupported_type',
                           commentable_type: commentable.class.to_s))
            end
            unless current_ability.can?(
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
                               .merge(comment_ability)
                               .merge(session_ability)
                               .merge(recording_ability)
        end

        def create_comment_params
          params.require(:comment).permit(
            :commentable_id,
            :commentable_type,
            :body
          )
        end

        def update_comment_params
          if current_ability.can?(:edit, @comment)
            params.require(:comment).permit(:body).tap { |attrs| attrs[:edited_at] = Time.now.utc }
          elsif current_ability.can?(:moderate, @comment)
            params.require(:comment).permit(:visible)
          else
            raise(AccessForbiddenError, I18n.t('controllers.api.v1.user.comments.errors.update_forbidden'))
          end
        end
      end
    end
  end
end
