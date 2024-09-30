# frozen_string_literal: true

module Api
  module V1
    module User
      class ReviewsController < Api::V1::User::ApplicationController
        before_action :review, only: %i[show update destroy]
        before_action :rates, only: %i[show destroy]

        helper_method :current_ability
        helper_method :review_ability

        def index
          query = ::Review.unscoped.visible_for_user(current_user)
          if params[:reviewable_id].present? && params[:reviewable_type].present?
            query = case reviewable.class.to_s
                    when 'Channel'
                      query.where(%(sessions.channel_id = :channel_id OR recordings.channel_id = :channel_id),
                                  channel_id: reviewable.id)
                    when 'Organization'
                      query.joins('LEFT JOIN channels on sessions.channel_id = channels.id OR recordings.channel_id = channels.id')
                           .where(channels: { organization_id: reviewable.id })
                    else
                      query.where(commentable: reviewable)
                    end
          end

          case params[:scope]
          when 'participant'
            query = query.where(rates: { dimension: Rate::RateKeys::QUALITY_OF_CONTENT })
          when 'organizer'
            query = query.where(rates: { dimension: Rate::RateKeys::IMMERSS_EXPERIENCE })
          end

          query = query.distinct(reviews: :id)
          query = query.where(user_id: params[:user_id]) if params[:user_id].present?

          if params[:created_at_from].present? || params[:created_at_to].present?
            from = params[:created_at_from].respond_to?(:to_datetime) ? params[:created_at_from].to_datetime : nil
            to = params[:created_at_to].respond_to?(:to_datetime) ? params[:created_at_to].to_datetime : nil

            if from.present? && to.present?
              query = query.where(reviews: { created_at: from..to })
            elsif from.present?
              query = query.where('reviews.created_at >= :from', from: from)
            elsif to.present?
              query = query.where('reviews.created_at <= :to', to: to)
            end
          end

          query = query.where(visible: params[:visible]) unless params[:visible].nil?

          @count = query.count
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
          @reviews = query.order(Arel.sql("reviews.id #{order}")).limit(@limit).offset(@offset).preload(%i[user
                                                                                                           commentable])
          @rates = {}

          if params[:reviewable_id].present? && params[:reviewable_type].present? && %w[Session
                                                                                        Recording].include?(reviewable.class.to_s)
            user_ids = @reviews.map(&:user_id)
            rates = ::Rate.where(rater_id: user_ids, rateable: reviewable)
          else
            rates = []
            @reviews.each do |review|
              next if (commentable_rates = ::Rate.where(rateable: review.commentable,
                                                        rater_id: review.user_id).to_a).blank?

              rates += commentable_rates
            end
          end

          rates.each do |rate|
            @rates[rate.rateable_type] ||= {}
            @rates[rate.rateable_type][rate.rateable_id] ||= {}
            @rates[rate.rateable_type][rate.rateable_id][rate.rater_id] ||= ::Rate::RateKeys::ALL.map do |key|
              [key, nil]
            end.to_h
            @rates[rate.rateable_type][rate.rateable_id][rate.rater_id][rate.dimension] = rate.stars
          end
        end

        def show
        end

        def create
          @reviewable = if params[:id].present? && params[:id] != 'current'
                          ::Review.find(params[:id]).commentable
                        else
                          params.require(:reviewable_type).classify.constantize.find(params.require(:reviewable_id))
                        end

          if @reviewable.is_a? Video
            if current_user != @reviewable.organizer && !current_user.confirmed?
              raise(AccessForbiddenError,
                    I18n.t('controllers.api.v1.user.reviews.errors.user_not_confirmed'))
            end
            if current_ability.cannot?(:rate, @reviewable)
              raise(AccessForbiddenError,
                    I18n.t('controllers.api.v1.user.reviews.errors.create_forbidden',
                           reviewable_type: @reviewable.class.to_s))
            end

            @reviewable = @reviewable.session
          end

          if current_ability.cannot?(:rate, reviewable)
            if current_user != reviewable.organizer && !current_user.confirmed?
              raise(AccessForbiddenError,
                    I18n.t('controllers.api.v1.user.reviews.errors.user_not_confirmed'))
            end

            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.user.reviews.errors.create_forbidden',
                         reviewable_type: reviewable.class.to_s))
          end

          update_rates_params.each do |dimension, stars|
            @reviewable.rate(stars, current_user, dimension)
          rescue NoMethodError
            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.user.reviews.errors.rate_forbidden', reviewable_type: reviewable.class.to_s,
                                                                                  dimension: dimension.humanize.downcase))
          end
          rates
          review
          if update_review_params.present?
            @review.attributes = update_review_params
            @review.save!
          end

          render :show
        end

        def update
          if current_user != reviewable.organizer && !current_user.confirmed?
            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.user.reviews.errors.user_not_confirmed'))
          end

          if current_ability.can?(:rate, reviewable)
            update_rates_params.each do |dimension, stars|
              reviewable.rate(stars, current_user, dimension)
            rescue NoMethodError
              raise(AccessForbiddenError,
                    I18n.t('controllers.api.v1.user.reviews.errors.rate_forbidden', reviewable_type: reviewable.class.to_s,
                                                                                    dimension: dimension.humanize.downcase))
            end
          end
          rates
          @review.update!(update_review_params) if update_review_params.present?

          render :show
        end

        def destroy
          raise ActiveRecord::RecordNotFound if @review.blank?

          if current_ability.cannot?(
            :edit, @review
          )
            raise(AccessForbiddenError,
                  I18n.t('controllers.api.v1.user.reviews.errors.destroy_forbidden',
                         reviewable_type: reviewable.class.to_s))
          end

          @review.destroy!
          render :show
        end

        private

        def reviewable
          @reviewable || begin
            @reviewable = if params[:id].present? && params[:id] != 'current'
                            ::Review.find(params[:id]).commentable
                          else
                            params.require(:reviewable_type).classify.constantize.find(params.require(:reviewable_id))
                          end
            @reviewable = @reviewable.session if @reviewable.is_a? Video
            unless @reviewable.respond_to?(:reviews)
              raise(ArgumentError,
                    I18n.t('controllers.api.v1.user.reviews.errors.type_not_allowed',
                           reviewable_type: @reviewable.class.to_s))
            end
            if action_name != 'index' && params[:id] == 'current' && %w[
              Session Recording
            ].exclude?(@reviewable.class.to_s)
              raise(ArgumentError,
                    I18n.t('controllers.api.v1.user.reviews.errors.type_not_allowed',
                           reviewable_type: @reviewable.class.to_s))
            end

            @reviewable
          end
        end

        def review
          @review ||= if params[:id].present? && params[:id] != 'current'
                        reviewable.reviews.find(params[:id])
                      else
                        reviewable.reviews.find_by(user: current_user)
                      end

          @review ||= reviewable.reviews.new(user: current_user) if %w[show update create].include?(action_name)
        end

        def rates
          @rates ||= begin
            rates = ::Session::RateKeys::ALL.map { |key| [key, nil] }.to_h

            ::Rate.where(rateable: reviewable, rater_id: current_user.id).each do |rate|
              rates[rate.dimension] = rate.stars
            end

            rates
          end
        end

        def current_ability
          @current_ability = session_ability.merge(recording_ability).merge(review_ability).merge(video_ability)
        end

        def update_review_params
          if current_ability.can?(:edit, @review)
            params.permit(:title, :overall_experience_comment, :technical_experience_comment)
          elsif current_ability.can?(:moderate, @review)
            params.permit(:visible)
          elsif current_ability.cannot?(:edit, @review) && current_ability.cannot?(:moderate, @review)
            raise(AccessForbiddenError, I18n.t('controllers.api.v1.user.reviews.errors.update_comment_forbidden'))
          end
        end

        def update_rates_params
          @update_rates_params ||= begin
            update_rates_params = case reviewable.class.to_s
                                  when 'Session'
                                    if current_user == reviewable.organizer
                                      params.permit(::Session::RateKeys::PRESENTER)
                                    else
                                      params.permit(::Session::RateKeys::USER)
                                    end
                                  when 'Recording'
                                    if current_user == reviewable.organizer
                                      params.permit
                                    else
                                      params.permit(::Recording::RateKeys::ALL)
                                    end
                                  else
                                    raise I18n.t('controllers.api.v1.user.reviews.errors.unsupported_reviewable',
                                                 reviewable_type: reviewable.class.to_s)
                                  end.reject { |_key, value| value.blank? }

            update_rates_params.each do |dimension, stars|
              next if (1..::Session::RATING_MAX_START).cover?(stars.to_f)

              raise(ArgumentError,
                    I18n.t('controllers.api.v1.user.reviews.errors.stars_out_of_range', stars: stars.to_i,
                                                                                        max_stars: ::Session::RATING_MAX_START, dimension: dimension))
            end

            update_rates_params
          end
        end
      end
    end
  end
end
