# frozen_string_literal: true
class SystemParameter < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  def self.freezed_const_set(key)
    const_set(key.upcase, key.downcase.freeze)
  end

  include ModelConcerns::SystemParameter::HasImmersiveSessionKeys
  include ModelConcerns::SystemParameter::HasNonImmersiveDeliveryMethodKeys

  validates :key, presence: true, uniqueness: true

  module Session
    module Keys
      MAX_NUMBER_OF_SESSION_IMMERSIVE_PARTICIPANTS = 'max_number_of_session_immersive_participants'
      MAX_NUMBER_OF_LIVESTREAM_FREE_TRIAL_SLOTS = 'max_number_of_livestream_free_trial_slots'
    end
  end

  module Refund
    FULL_MONEY_OR_CREDIT_NOT_SOONER_THAN_HOURS  = 'full_money_or_credit_not_sooner_than_hours'
    HALF_CREDIT_NOT_SOONER_THAN_HOURS           = 'half_credit_not_sooner_than_hours'
  end

  CO_PRESENTER_FEE = 'co_presenter_fee'

  REFERRAL_PARTICIPANT_FEE_IN_PERCENT = 'referral_participant_fee_in_percent'

  BOOK_AHEAD_IN_HOURS_MAX = 'book_ahead_in_hours_max'
  CHECK_SLOTS_HOURS_BEFORE_START = 'check_slots_hours_before_start'

  CHANNEL_IMAGES_MAX_COUNT = 'channel_images_max_count'
  CHANNEL_LINKS_MAX_COUNT  = 'channel_links_max_count'

  MIN_SESSION_CANCELLATION_FEE_PER_PAID_IMMERSIVE_PARTICIPANT = 'min_session_cancellation_fee_per_paid_immersive_participant'
  MIN_SESSION_CANCELLATION_FEE_PER_PAID_LIVESTREAM_PARTICIPANT = 'min_session_cancellation_fee_per_paid_livestream_participant'

  MAX_SESSION_CANCELLATION_FEE_PER_PAID_IMMERSIVE_PARTICIPANT = 'max_session_cancellation_fee_per_paid_immersive_participant'
  MAX_SESSION_CANCELLATION_FEE_PER_PAID_LIVESTREAM_PARTICIPANT = 'max_session_cancellation_fee_per_paid_livestream_participant'

  after_save do
    if Rails.env.qa? || Rails.env.production?
      Mailer.system_parameter_changed(self).deliver_later
    end

    Rails.logger.info "[sysparam] deleting cache key for #{key}"
    Rails.cache.delete(key.to_s)

    result = SystemParameter.send(key)

    Rails.logger.info "[sysparam] SystemParameter.#{key} returned #{result.inspect}"
  end

  # @return [Float]
  def self.min_session_cancellation_fee_per_paid_immersive_participant
    fetch_value(MIN_SESSION_CANCELLATION_FEE_PER_PAID_IMMERSIVE_PARTICIPANT)
  end

  # @return [Float]
  def self.max_session_cancellation_fee_per_paid_immersive_participant
    fetch_value(MAX_SESSION_CANCELLATION_FEE_PER_PAID_IMMERSIVE_PARTICIPANT)
  end

  # @return [Float]
  def self.min_session_cancellation_fee_per_paid_livestream_participant
    fetch_value(MIN_SESSION_CANCELLATION_FEE_PER_PAID_LIVESTREAM_PARTICIPANT)
  end

  # @return [Float]
  def self.max_session_cancellation_fee_per_paid_livestream_participant
    fetch_value(MAX_SESSION_CANCELLATION_FEE_PER_PAID_LIVESTREAM_PARTICIPANT)
  end

  # @return [Integer]
  def self.channel_images_max_count
    fetch_value(CHANNEL_IMAGES_MAX_COUNT)
  end

  # @return [Integer]
  def self.channel_links_max_count
    fetch_value(CHANNEL_LINKS_MAX_COUNT)
  end

  # @return [Integer]
  def self.max_number_of_immersive_participants
    fetch_value(Session::Keys::MAX_NUMBER_OF_SESSION_IMMERSIVE_PARTICIPANTS)
  end

  # @return [Integer]
  def self.max_number_of_livestream_free_trial_slots
    fetch_value(Session::Keys::MAX_NUMBER_OF_LIVESTREAM_FREE_TRIAL_SLOTS)
  end

  # @return [Integer]
  def self.book_ahead_in_hours_max
    fetch_value(BOOK_AHEAD_IN_HOURS_MAX)
  end

  # @return [Float]
  def self.referral_participant_fee_in_percent
    fetch_value(REFERRAL_PARTICIPANT_FEE_IN_PERCENT)
  end

  # @return [Integer]
  def self.full_money_or_credit_not_sooner_than_hours
    fetch_value(Refund::FULL_MONEY_OR_CREDIT_NOT_SOONER_THAN_HOURS)
  end

  # @return [Integer]
  def self.half_credit_not_sooner_than_hours
    fetch_value(Refund::HALF_CREDIT_NOT_SOONER_THAN_HOURS)
  end

  # @return [Integer]
  def self.check_slots_hours_before_start
    fetch_value(CHECK_SLOTS_HOURS_BEFORE_START)
  end

  # @return [BigDecimal]
  def self.co_presenter_fee
    fetch_value(CO_PRESENTER_FEE)
  end

  ###

  def self.fetch_value(key)
    # Rails.cache.fetch(key.to_s) do
    #  begin
    #    find_by_key!(key.to_s).value
    #  rescue ActiveRecord::RecordNotFound => e
    #    raise "key: #{key.inspect} - #{e.message}"
    #  end
    # end
    find_by!(key: key.to_s).value
  end
end
