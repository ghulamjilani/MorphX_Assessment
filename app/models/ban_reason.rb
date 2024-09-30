# frozen_string_literal: true
class BanReason < ActiveRecord::Base
  include ModelConcerns::ActiveModel::Extensions

  validates :name, presence: true, uniqueness: true
end
