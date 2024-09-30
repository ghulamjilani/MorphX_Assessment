# frozen_string_literal: true

envelope json, (@status || 200), @review.pretty_errors.presence do
  can_read_technical_comment = review_ability.can?(:read_technical_experience_comment, @review)
  json.review do
    json.partial! 'review', review: @review
    if can_read_technical_comment
      json.technical_experience_comment @review.technical_experience_comment
    end
  end
  json.rates do
    @rates.each do |dimension, stars|
      stars = nil if dimension != 'quality_of_content' && !can_read_technical_comment

      json.set!(dimension, stars)
    end
  end
  json.user do
    json.partial! 'api/v1/public/users/user_short', model: @review.user
  end
  json.reviewable do
    json.always_present_title @review.commentable.always_present_title
    json.absolute_path        @review.commentable.absolute_path
    json.creator_id           @review.commentable.organizer.id
  end
end
