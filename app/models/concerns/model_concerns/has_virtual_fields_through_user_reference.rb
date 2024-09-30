# frozen_string_literal: true

module ModelConcerns::HasVirtualFieldsThroughUserReference
  extend ActiveSupport::Concern

  included do
    belongs_to :user, touch: true
    # this is needed to highlight errors when we primary presenter
    # adds co-presenters to session
    validate :email_validness_when_co_presenter
  end

  def email_validness_when_co_presenter
    if user_id.blank? && user.present? && !user.valid? && user.errors[:email].present?
      errors.add(:email, user.errors[:email].join(', '))
    end
  end

  def email
    user.try(:email)
  end

  def display_name
    user.try(:display_name)
  end

  def avatar_url
    user ? user.avatar_url : UserAccount.new.image_preview_url
  end
end
