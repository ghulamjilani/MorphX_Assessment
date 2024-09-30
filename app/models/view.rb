# frozen_string_literal: true
class View < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :user
  belongs_to :viewable, polymorphic: true, optional: false
  before_validation :set_group_name, unless: :group_name?

  validates :group_name, presence: true
  validate :user_id_or_ip_presence

  scope :counted, -> { where.not(counted_at: nil) }
  scope :not_counted, -> { where(counted_at: nil) }

  def user_id_or_ip
    user_id || ip_address
  end

  private

  def set_group_name
    self.group_name = viewable&.unique_view_group_name(user_id_or_ip)
  end

  def user_id_or_ip_presence
    errors.add(:ip_address, 'user_id or ip_address must be present') if user_id.blank? && ip_address.blank?
  end
end
