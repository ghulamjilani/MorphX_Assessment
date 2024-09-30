# frozen_string_literal: true

module ModelConcerns::User::HasConfigurableCoefficients
  extend ActiveSupport::Concern

  included do
    validate :profit_margin_percent_format
    before_validation :set_default_revenue_split_coefficient

    validate :referral_participant_fee_in_percent_format
    before_validation :set_default_referral_participant_fee_in_percent
  end

  def set_default_revenue_split_coefficient
    if profit_margin_percent.blank?
      # user gets 70% cut
      self.profit_margin_percent = 70.0
    end
  end

  def set_default_referral_participant_fee_in_percent
    if referral_participant_fee_in_percent.blank?
      # master presenter gets 5% from referral purchases
      self.referral_participant_fee_in_percent = SystemParameter.referral_participant_fee_in_percent
    end
  end

  private

  def profit_margin_percent_format
    if profit_margin_percent.to_f.negative?
      errors.add(:profit_margin_percent, :greater_than, count: 0)
    elsif profit_margin_percent.to_f > 100
      errors.add(:profit_margin_percent, :less_than, count: 100)
    end
  end

  def referral_participant_fee_in_percent_format
    if referral_participant_fee_in_percent.to_f <= 0
      errors.add(:referral_participant_fee_in_percent, :greater_than, count: 0)
    elsif referral_participant_fee_in_percent.to_f >= 100
      errors.add(:referral_participant_fee_in_percent, :less_than, count: 100)
    end
  end
end
