# frozen_string_literal: true
class InteractiveAccessToken < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :session, required: true
  has_one :room, through: :session

  validate :token_validation
  # validates :session_id, uniqueness: { scope: [:individual, :guests] }, if: ->(t) { !t.individual? }

  scope :individual,     -> { where(individual: true) }
  scope :shared,         -> { where(individual: false) }
  scope :with_guests,    -> { where(guests: true) }
  scope :without_guests, -> { where(guests: false) }

  def refresh_token
    self.token = SecureRandom.alphanumeric(16)
  end

  def refresh_token!
    update!(token: SecureRandom.alphanumeric(16))
  end

  def absolute_url
    return nil unless persisted?

    Rails.application.routes.url_helpers.join_interactive_by_token_spa_rooms_url(token)
  end

  def title
    @title ||= "Direct Permalink (#{guests? ? '' : 'No '}Guests Allowed#{'; Individual' if individual?})"
  end

  private

  def token_validation
    refresh_token while need_new_token?
  end

  def need_new_token?
    token.blank? || InteractiveAccessToken.where.not(id: id).exists?(token: token)
  end
end
