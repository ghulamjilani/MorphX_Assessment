# frozen_string_literal: true

module ModelConcerns::User::ActsAsOmniauthUser
  extend ActiveSupport::Concern

  included do
    has_many :identities, dependent: :destroy
    serialize :facebook_friends
  end

  def facebook_identity
    @facebook_identity ||= identities.where(provider: 'facebook').last
  end

  def twitter_identity
    @twitter_identity ||= identities.where(provider: 'twitter').last
  end

  def gplus_identity
    @gplus_identity ||= identities.where(provider: 'gplus').last
  end

  def linkedin_identity
    @linkedin_identity ||= identities.where(provider: 'linkedin').last
  end

  def instagram_identity
    @instagram_identity ||= identities.where(provider: 'instagram').last
  end

  def zoom_identity
    @zoom_identity ||= identities.where(provider: 'zoom').last
  end

  def twitter_client
    # @twitter_client ||= Twitter.client(access_token: twitter_identity.token )
  end

  def facebook_client
    @facebook_client ||= Facebook.client(access_token: facebook_identity.token)
  end

  def instagram_client
    # @instagram_client ||= Instagram.client(access_token: instagram_identity.token )
  end

  def gplus_client
    unless @gplus_client
      @gplus_client = Google::APIClient.new(application_name: ENV['GPLUS_APP_NAME'],
                                            application_version: ENV['GPLUS_APP_VERSION'])
      @gplus_client.authorization.update_token!({ access_token: gplus_identity.token,
                                                  refresh_token: gplus_identity.secret })
    end
    @gplus_client
  end

  include ModelConcerns::User::ActsAsFacebookUser
  include ModelConcerns::User::ActsAsGplusUser
  include ModelConcerns::User::ActsAsAppleUser
  include ModelConcerns::User::ActsAsTwitterUser
  include ModelConcerns::User::ActsAsLinkedinUser
  include ModelConcerns::User::ActsAsInstagramUser
  include ModelConcerns::User::ActsAsZoomUser

  PROVIDERS = {
    facebook: 'Facebook',
    gplus: 'Google+',
    twitter: 'Twitter',
    linkedin: 'Linkedin',
    apple: 'Apple',
    instagram: 'Instagram',
    zoom: 'Zoom'
  }.freeze

  PROVIDERS.keys.each do |provider|
    define_method("connect_#{provider}") do |payload|
      identity = identities.where(provider: payload.provider).first

      if identity.present?
        if identity.uid != payload.uid
          identity.update_attribute(uid: payload.uid)
        end
      else
        identities.create!(
          provider: payload.provider,
          uid: payload.uid,
          expires: payload.credentials.expires,
          expires_at: payload.credentials.expires_at,
          token: payload.credentials.token,
          secret: payload.credentials.secret || payload.credentials.refresh_token
        )
      end
      self
    end
  end

  module ClassMethods
    PROVIDERS.keys.each do |provider|
      define_method("find_or_connect_to_#{provider}") do |payload|
        send("find_from_#{provider}".to_sym, payload) || send("connect_to_#{provider}".to_sym, payload)
      end

      define_method("find_from_#{provider}") do |payload|
        Identity.where(provider: payload.provider, uid: payload.uid).first.try(:user)
      end
    end
  end

  # Devise RegistrationsController by default calls "User.new_with_session" before building a resource.
  # This means that, if we need to copy data from session whenever a user is initialized before sign up,
  # we just need to implement new_with_session in our model.
  #
  # @see https://github.com/plataformatec/devise/wiki/OmniAuth%3A-Overview
  def new_with_session(params, session)
    super.tap do |user|
      payload = PROVIDERS.keys.detect { |provider| session["devise.#{provider}_data"] }
      if payload.present? && user.email.blank?
        user.email = payload['email']
      end
    end
  end
end
