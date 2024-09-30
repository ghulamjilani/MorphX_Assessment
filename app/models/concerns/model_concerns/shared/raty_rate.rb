# frozen_string_literal: true

module ModelConcerns::Shared::RatyRate
  extend ActiveSupport::Concern

  def raters_count(dimension = Rate::RateKeys::QUALITY_OF_CONTENT)
    @raters_count ||= Rate.select(:rater_id).where(rateable_id: id, rateable_type: self.class.to_s,
                                                   dimension: dimension).distinct.count
  end

  def rate_as_new_or_update_existing(stars, user, dimension = nil, _dirichlet_method = false)
    dimension = nil if dimension.blank?

    if Rate.where(rater: user, dimension: dimension, rateable: self).blank?
      rates(dimension).create! do |r|
        r.stars = stars
        r.rater = user
      end
      update_rate_average(stars, dimension)
    else
      update_current_rate(stars, user, dimension)
    end
  end
end
