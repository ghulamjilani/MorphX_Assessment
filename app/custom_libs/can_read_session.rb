# frozen_string_literal: true

class CanReadSession
  def initialize(user, session)
    @user    = user
    @session = session

    @message_key = nil
  end

  module MessageKeys
    ADULT = 'adult'
    PRIVATE = 'private'
    FORBIDDEN = 'forbidden'
    FREE_SESSION_PENDING_REVIEW = 'free_session_pending_review'

    ALL = [
      ADULT,
      PRIVATE,
      FORBIDDEN,
      FREE_SESSION_PENDING_REVIEW
    ].freeze
  end

  def can?
    user_cache_key = @user.try(:cache_key) # could be not logged in/nil
    @channel = @session.channel

    cache = Rails.cache.fetch("ability/read/#{@session.cache_key}/#{user_cache_key}") do
      lambda do
        unless @channel.organization.active_subscription_or_split_revenue?
          return { result: false, message_key: MessageKeys::FORBIDDEN }
        end

        if Rails.application.credentials.global[:enterprise] && (!@user.is_a?(User) || !@user.persisted? || !@user.has_channel_credential?(
          @channel, :view_content
        ))
          return { result: false, message_key: MessageKeys::FORBIDDEN }
        end

        if @user.is_a?(User) && @user.persisted?
          return { result: true, message_key: nil } if @user.service_admin? || @user.platform_owner?

          if @session.presenter_id == @user.presenter_id || @channel.organizer == @user
            return { result: true,
                     message_key: nil }
          end
        end

        if @session.age_restrictions == Session::AGE_RESTRICTIONS[:adult] && (@user.blank? || @user.new_record? || @user.birthdate.blank? || @user.birthdate > 18.years.ago)
          return { result: false, message_key: MessageKeys::ADULT }
        end

        if @session.age_restrictions == Session::AGE_RESTRICTIONS[:major] && (@user.blank? || @user.birthdate.blank? || @user.birthdate > 21.years.ago)
          return { result: false, message_key: MessageKeys::ADULT }
        end

        if @user.present? && @user.persisted? && @user.participant_id.present? && (@session.has_immersive_participant?(@user.participant_id) || @session.session_invited_immersive_participantships.where(participant: @user.participant).present?)
          return { result: true, message_key: nil }
        end

        if @user.present? && @user.persisted? && @user.participant_id.present? && (@session.has_livestream_participant?(@user.participant_id) || @session.session_invited_livestream_participantships.where(participant: @user.participant).present?)
          return { result: true, message_key: nil }
        end

        if @user.present? && @user.persisted? && @user.presenter.present? && (@session.has_co_presenter?(@user.presenter_id) || @session.session_invited_immersive_co_presenterships.where(presenter: @user.presenter).present?)
          return { result: true, message_key: nil }
        end

        if @session.private?
          return { result: false, message_key: MessageKeys::PRIVATE }
        end

        if @channel.organizer != @user && @channel.organizer.fake?
          return { result: false, message_key: MessageKeys::PRIVATE }
        end

        if @session.status.to_s == Session::Statuses::REQUESTED_FREE_SESSION_PENDING
          return { result: false, message_key: MessageKeys::FREE_SESSION_PENDING_REVIEW }
        end

        return { result: true, message_key: nil }
      end.call
    end

    @message_key = cache[:message_key]
    cache[:result]
  end

  def cannot_because_of_message(explicit_key = nil)
    key = explicit_key || @message_key
    return if key.blank?

    I18n.t("cancan.unauthorized.sessions.because_of.#{key}")
  end

  # otherwise it would be always broken and not working
  def verify_all_keys
    MessageKeys::ALL.each do |key|
      puts cannot_because_of_message(key)
    end
  end
end
