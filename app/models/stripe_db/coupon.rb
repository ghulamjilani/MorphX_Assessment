# frozen_string_literal: true
class StripeDb::Coupon < ActiveRecord::Base
  attr_accessor :push_to_stripe

  after_create :create_on_stripe, if: :push_to_stripe
  before_destroy :destroy_on_stripe

  TARGET_TYPES = %w[StripeDb::Plan StripeDb::ServicePlan Channel].freeze
  TARGET_TYPE_OPTIONS = [
    ['Channel Subscription Plan', 'StripeDb::Plan'],
    ['Business Subscription Plan', 'StripeDb::ServicePlan'],
    ['Channel Subscriptions', 'Channel']
  ].freeze
  DURATIONS = %w[forever once repeating].freeze

  def self.create_or_update_from_stripe(sid)
    response = Stripe::Coupon.retrieve(sid)
    object = find_or_initialize_by(stripe_id: response.id)
    object.name = response.name
    object.amount_off = response.amount_off
    object.percent_off_precise = response.percent_off
    object.duration = response.duration
    object.duration_in_months = response.duration_in_months
    object.redeem_by = begin
      DateTime.strptime(response.redeem_by.to_s, '%s')
    rescue StandardError
      nil
    end
    object.is_valid = response.valid

    object.save
    object
  end

  def stripe_object
    @stripe_object ||= Stripe::Coupon.retrieve(stripe_id)
  end

  def valid_for?(object)
    stripe_object.valid &&
      (target_type.blank? || # any
        (target_type == object.class.name && [nil, '', object.id].include?(target_id))) # any/one of one target type
  end

  def calc_savings(payment_amount_cents)
    if amount_off
      if payment_amount_cents.to_i > amount_off
        amount_off
      else
        payment_amount_cents.to_i
      end
    elsif percent_off_precise
      payment_amount_cents.to_i * percent_off_precise / 100
    else
      raise 'No Amount Off provided'
    end
  end

  private

  def create_on_stripe
    params = {
      name: name,
      amount_off: amount_off,
      currency: ('usd' if amount_off),
      percent_off: percent_off_precise,
      duration: duration,
      duration_in_months: duration_in_months,
      redeem_by: redeem_by&.to_i
    }
    params[:id] = stripe_id if stripe_id.present?
    response = Stripe::Coupon.create(params)
    update(stripe_id: response.id)
  end

  def destroy_on_stripe
    return true if Rails.env.test?

    begin
      result = stripe_object.delete
      raise 'Can not delete coupon' unless result.deleted
    rescue StandardError => e
      unless e.message.start_with?('No such coupon:')
        raise e.message
      end
    end
  end
end
