# frozen_string_literal: true
class ChannelType < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  has_many :channels

  module Descriptions
    INSTRUCTIONAL = 'Instructional'
    PERFORMANCE   = 'Performance'
    SOCIAL        = 'Social'
    NOT_SELECTED  = 'Not Selected'

    ALL = [NOT_SELECTED, INSTRUCTIONAL, PERFORMANCE, SOCIAL].freeze
  end

  unless Rails.env.test?
    validates :description, presence: true, inclusion: { in: Descriptions::ALL }
    validates :description, uniqueness: true
  end

  def self.not_selected
    where(description: Descriptions::NOT_SELECTED).first
  end

  def self.instructional
    where(description: Descriptions::INSTRUCTIONAL).first
  end

  def self.performance
    where(description: Descriptions::PERFORMANCE).first
  end

  def self.social
    where(description: Descriptions::SOCIAL).first
  end
end
