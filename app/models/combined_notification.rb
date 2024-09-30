# frozen_string_literal: true
class CombinedNotification < ActiveRecord::Base
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :combined_notification_setting
  belongs_to :record, polymorphic: true
end
