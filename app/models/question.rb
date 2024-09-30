# frozen_string_literal: true
class Question < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :session, touch: true
  belongs_to :user

  validates :session_id, uniqueness: { scope: :user_id }
  validates :session, :user, presence: true
end
