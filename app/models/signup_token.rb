# frozen_string_literal: true
class SignupToken < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  class << self
    def lifetime_days
      Rails.application.credentials.backend.dig(:signup_tokens, :lifetime_days).to_i
    end
  end

  belongs_to :user

  validate :token_validation
  validate :user_validation, if: :persisted?
  validate :created_at_validation, if: :persisted?

  scope :used, -> { where.not(user_id: nil) }
  scope :not_used, -> { where(user_id: nil) }
  scope :not_expired, lambda {
    return where(nil) if SignupToken.lifetime_days.zero?

    where('user_id IS NULL AND created_at > :created_after', created_after: SignupToken.lifetime_days.days.ago)
  }
  scope :usable, -> { not_used.not_expired }

  delegate :organization, to: :user, allow_nil: true

  def expired?
    return false if SignupToken.lifetime_days.zero?

    created_at < SignupToken.lifetime_days.days.ago
  end

  def used?
    user_id.present?
  end

  def usable?
    !expired? && !used?
  end

  def refresh_token
    self.token = SecureRandom.alphanumeric(16)
  end

  def user_attributes
    attributes.symbolize_keys.slice(:can_use_wizard, :can_buy_subscription)
  end

  def used_by!(user)
    used_by(user) || raise(ActiveRecord::RecordInvalid, self)
  end

  def used_by(user)
    errors.add(:user, I18n.t('models.signup_token.errors.already_used')) if used?
    errors.add(:base, I18n.t('models.signup_token.errors.not_usable')) unless usable?

    return false if errors.present?

    SignupToken.transaction do
      update!(user: user)
      user.update!(user_attributes)
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.message)
      false
    end
  end

  private

  def token_validation
    refresh_token while need_new_token?
  end

  def need_new_token?
    token.blank? || SignupToken.where.not(id: id).exists?(token: token)
  end

  def user_validation
    if user_id_was.present?
      # token cannot be changed after being used
      errors.add(:user_id, I18n.t('models.signup_token.errors.already_used'))
      return false
    end

    return true if user_id.blank?

    errors.add(:user_id, I18n.t('models.signup_token.errors.user_validation')) unless user.is_a?(User) && user.persisted?

    self.used_at = Time.now.utc if used_at.blank?
  end

  def created_at_validation
    errors.add(:created_at, I18n.t('models.signup_token.errors.expired')) if expired?
  end
end
