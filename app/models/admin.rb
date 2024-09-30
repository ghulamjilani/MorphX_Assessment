# frozen_string_literal: true
class Admin < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::BelongsToTimezone

  has_many :admin_logs
  attribute :role, :integer
  devise :database_authenticatable,
         :timeoutable,
         :rememberable, timeout_in: 3.hours
  enum role: {
    morphx_admin: 0,
    platform_admin: 1,
    superadmin: 2
  }
end
