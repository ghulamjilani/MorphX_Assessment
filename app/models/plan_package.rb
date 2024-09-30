# frozen_string_literal: true
class PlanPackage < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  has_many :plans, class_name: 'StripeDb::ServicePlan'
  has_many :service_subscriptions, through: :plans
  has_many :feature_parameters
  accepts_nested_attributes_for :plans, allow_destroy: true
  accepts_nested_attributes_for :feature_parameters, allow_destroy: true

  def is_multi_room?
    %w[t true].include?(feature_parameters.by_code(:multi_room).first.value)
  rescue StandardError
    false
  end

  def max_channels_count
    feature_parameters.by_code(:max_channels_count).first.value.to_i
  rescue StandardError
    0
  end

  def max_admins_count
    feature_parameters.by_code(:max_admins_count).first.value.to_i
  rescue StandardError
    0
  end

  def max_creators_count
    feature_parameters.by_code(:max_creators_count).first.value.to_i
  rescue StandardError
    0
  end

  def max_members_count
    feature_parameters.by_code(:max_members_count).first.value.to_i
  rescue StandardError
    0
  end

  def storage
    feature_parameters.by_code(:storage).first.value.to_i
  rescue StandardError
    0
  end

  def streaming_time
    feature_parameters.by_code(:streaming_time).first.value.to_i
  rescue StandardError
    0
  end

  def transcoding_time
    feature_parameters.by_code(:transcoding_time).first.value.to_i
  rescue StandardError
    0
  end

  def is_interactive_stream?
    %w[t true].include?(feature_parameters.by_code(:interactive_stream).first.value)
  rescue StandardError
    false
  end

  def is_private_session_available?
    %w[t true].include?(feature_parameters.by_code(:private_sessions).first.value)
  rescue StandardError
    false
  end

  def is_blog_available?
    %w[t true].include?(feature_parameters.by_code(:community_blog).first.value)
  rescue StandardError
    false
  end

  def instream_shopping?
    %w[t true].include?(feature_parameters.by_code(:instream_shopping).first.value)
  rescue StandardError
    false
  end

  def manage_creators?
    %w[t true].include?(feature_parameters.by_code(:manage_creators).first.value)
  rescue StandardError
    false
  end

  def manage_admins?
    %w[t true].include?(feature_parameters.by_code(:manage_admins).first.value)
  rescue StandardError
    false
  end
end
