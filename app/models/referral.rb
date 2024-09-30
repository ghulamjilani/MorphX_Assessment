# frozen_string_literal: true
class Referral < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :master_user, class_name: 'User', foreign_key: 'master_user_id'
  belongs_to :referral_code
  belongs_to :user

  validates :user_id, uniqueness: { scope: :master_user_id }

  def object_label
    user.object_label
  end
end
