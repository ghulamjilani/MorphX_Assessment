# frozen_string_literal: true
class AdminLog < ActiveRecord::Base
  belongs_to :admin
  belongs_to :loggable, polymorphic: true
  serialize :differences
end
