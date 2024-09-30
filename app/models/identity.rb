# frozen_string_literal: true
class Identity < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  module Providers
    FACEBOOK = 'facebook'
    GPLUS    = 'gplus'
    LINKEDIN = 'linkedin'
    TWITTER  = 'twitter'
  end

  belongs_to :user, touch: true

  validates :user, :provider, presence: true

  validates :uid, uniqueness: { scope: :provider }
  validates :provider, uniqueness: { scope: %i[user_id uid] }

  validate :twitter_credentials,  if: proc { |obj| obj.provider.to_s == Providers::TWITTER }
  validate :facebook_credentials, if: proc { |obj| obj.provider.to_s == Providers::FACEBOOK }

  def object_label
    "#{provider}/#{user.object_label}"
  end

  private

  def twitter_credentials
    errors.add(:token, :blank) if token.blank?
    errors.add(:secret, :blank) if secret.blank?
  end

  def facebook_credentials
    errors.add(:token, :blank) if token.blank?
    errors.add(:expires, :blank) if expires.blank?
    errors.add(:expires_at, :blank) if expires_at.blank?
  end
end
