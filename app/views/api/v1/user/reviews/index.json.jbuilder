# frozen_string_literal: true

envelope json do
  json.reviews do
    json.array! @reviews do |review|
      can_read_technical_comment = review_ability.can?(:read_technical_experience_comment, review)
      json.review do
        json.partial! 'review', review: review
      end
      json.rates do
        @rates.dig(review.commentable_type, review.commentable_id, review.user_id).to_h.each do |dimension, stars|
          stars = nil if dimension != 'quality_of_content' && !can_read_technical_comment

          json.set!(dimension, stars)
        end
      end
      json.user do
        json.partial! 'api/v1/public/users/user_short', model: review.user
      end
      json.reviewable do
        reviewable = review.commentable
        json.always_present_title reviewable.always_present_title
        json.absolute_path        reviewable.try(:records)&.first&.absolute_path || reviewable.absolute_path
      end
    end
  end
end
