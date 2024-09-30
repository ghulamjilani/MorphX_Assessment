# frozen_string_literal: true

module Api
  module V1
    module Public
      class ReviewsController < Api::V1::Public::ApplicationController
        def index
          query = ::Review.unscoped.visible.from_participants
          query = case reviewable.class.to_s
                  when 'Channel'
                    query.where(%(sessions.channel_id = :channel_id OR recordings.channel_id = :channel_id),
                                channel_id: reviewable.id)
                  when 'Organization'
                    query.joins('LEFT JOIN channels on sessions.channel_id = channels.id OR recordings.channel_id = channels.id')
                         .where(channels: { organization_id: reviewable.id })
                  else
                    query.where(commentable: reviewable)
                  end.distinct(reviews: :id)

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

          @count = query.count
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
          @reviews = query.order(Arel.sql("id #{order}")).limit(@limit).offset(@offset).preload(%i[user commentable])
          @rates = {}

          if %w[Session Recording].include?(reviewable.class.to_s)
            rates = reviewable.rates(Rate::RateKeys::QUALITY_OF_CONTENT).where(rater_id: @reviews.map(&:user_id))
          else
            rates = []
            @reviews.each do |review|
              next unless (rate = review.commentable.rates(Rate::RateKeys::QUALITY_OF_CONTENT).find_by(rater_id: review.user_id))

              rates << rate
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

        private

        def reviewable
          @reviewable || begin
            @reviewable = params.require(:reviewable_type).classify.constantize.find(params.require(:reviewable_id))
            @reviewable = @reviewable.session if @reviewable.is_a? Video
            unless @reviewable.respond_to?(:reviews)
              raise(ArgumentError,
                    I18n.t('controllers.api.v1.public.reviews.errors.unsupported_type',
                           reviewable_type: @reviewable.class.to_s))
            end
            unless current_ability.can?(
              :read, @reviewable
            )
              raise(ArgumentError,
                    I18n.t('controllers.api.v1.public.reviews.errors.read_forbidden',
                           reviewable_type: @reviewable.class.to_s))
            end

            @reviewable
          end
        end
      end
    end
  end
end
