# frozen_string_literal: true
class Partner < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  serialize :hosts, Array
  belongs_to :category, class_name: 'ChannelCategory'
end
