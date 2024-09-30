# frozen_string_literal: true

envelope json do
  json.reviews do
    json.array! @reviews do |review|
      json.review do
        json.partial! 'review', review: review
      end
      json.rates do
        @rates.dig(review.commentable_type, review.commentable_id, review.user_id).to_h.each do |dimension, stars|
          stars = nil if dimension != ::Rate::RateKeys::QUALITY_OF_CONTENT

          json.set!(dimension, stars)
        end
      end
      json.user do
        json.partial! 'api/v1/public/users/user_short', model: review.user
      end
      json.reviewable do
        reviewable = review.commentable
        json.always_present_title reviewable.always_present_title
        json.absolute_path        reviewable.absolute_path
      end
    end
  end
end
