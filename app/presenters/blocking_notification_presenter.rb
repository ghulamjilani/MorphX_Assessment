# frozen_string_literal: true

class BlockingNotificationPresenter
  def initialize(current_user, ability)
    @current_user = current_user
    @ability      = ability
  end

  def notifications
    result = []
    return result if models_invited_to.blank?

    models_invited_to.each_with_index do |model_invited_to, _i|
      options = {
        model_invited_to: model_invited_to,
        current_user: @current_user,
        ability: @ability
      }
      invitation_interactor = "#{model_invited_to.class}InvitationButtonsPresenter".constantize.new(options)

      message               = invitation_interactor.message
      decline_html          = invitation_interactor.decline_html('flash__container__infinite__buttons__decline btn btn__bordered btn__xs')
      accept_html           = invitation_interactor.accept_html('flash__container__infinite__buttons__accept btn btn__save btn__xs')

      html = <<~EOL
                <div class="FlashBox-B">
                  #{message}
        #{'        '}
                  <div class="FlashBox-F">
                    #{if model_invited_to.is_a?(Session)
                        "#{model_invited_to.start_at.in_time_zone(@current_user.timezone).strftime('%d %b %I:%M %p %Z')}
                      #{model_invited_to.duration} Min"
                      end}
                    <div class="FlashBox-btnBox">
                      #{decline_html}
                      #{accept_html}
                    </div>
                  </div>
                </div>
      EOL
      notification_data = {
        id: model_invited_to.id,
        type: model_invited_to.class.name,
        title: model_invited_to.always_present_title,
        html: html
      }
      if model_invited_to.is_a?(Session)
        notification_data[:livestream_purchase_price] =
          if model_invited_to.livestream_delivery_method?
            ActiveSupport::NumberHelper.number_to_currency(
              model_invited_to.livestream_purchase_price.to_f, precision: 2
            )
          end
        notification_data[:immersive_purchase_price] =
          if model_invited_to.immersive_delivery_method?
            ActiveSupport::NumberHelper.number_to_currency(
              model_invited_to.immersive_purchase_price.to_f, precision: 2
            )
          end
      end
      result << notification_data
    end

    result
  end

  def to_s
    return '' if models_invited_to.blank?

    result = ''
    models_invited_to.each_with_index do |model_invited_to, i|
      options = {
        model_invited_to: model_invited_to,
        current_user: @current_user,
        ability: @ability
      }
      invitation_interactor = "#{model_invited_to.class}InvitationButtonsPresenter".constantize.new(options)

      message               = invitation_interactor.message
      decline_html          = invitation_interactor.decline_html('btn btn-s btn-borderred-secondary')
      accept_html           = invitation_interactor.accept_html('btn btn-s')
      forcefully_close_path = invitation_interactor.forcefully_close_path

      result += <<~EOL
                <div data-id='#{model_invited_to.class}#{model_invited_to.id}' class='FlashBox' style='display: none'>
                  #{unless model_invited_to.is_a?(Organization)
                      "<button class='close VideoClientIcon-iPlus rotateIcon' type='button' data-dismiss='alert'></button>"
                    end}
                  <div class="FlashBox-h">
                    <div class="FlashBox-Title">
                      #{model_invited_to.title}
                    </div>
                    <div class="FlashBox-count">
                      #{unless models_invited_to.size < 2
                          "<a class='prev-popup-notification ensure-link-style'><</a>
                        <span>
                          #{i + 1}/#{models_invited_to.size}
                        </span>
                        <a class='next-popup-notification ensure-link-style'>></a>"
                        end}
                    </div>
                  </div>
                  <div class="FlashBox-B">
                    #{message}
        #{'        '}
                    <div class="FlashBox-F">
                      #{if model_invited_to.is_a?(Session)
                          "#{model_invited_to.start_at.in_time_zone(@current_user.timezone).strftime('%d %b %I:%M %p %Z')}
                       #{model_invited_to.duration} Min"
                        end}
                      <div class="FlashBox-btnBox">
                        #{decline_html}
                        #{accept_html}
                      </div>
                    </div>
                  </div>
                </div>
      EOL
    end

    result
  end

  def models_invited_to
    @models_invited_to = pending_user_invites.select do |model_invited_to|
      lambda do
        unless @ability.can?(:accept_or_reject_invitation, model_invited_to)
          return false
        end

        case model_invited_to
        when Session
          session = model_invited_to

          immersive_invited = @current_user.present? \
            && @current_user.participant.present? \
            && session.session_invited_immersive_participantships.where(participant: @current_user.participant).pending.present?

          livestream_invited = @current_user.present? \
            && @current_user.participant.present? \
            && session.session_invited_livestream_participantships.where(participant: @current_user.participant).pending.present?

          invited_as_co_presenter = @current_user.present? \
            && @current_user.presenter.present? \
            && session.session_invited_immersive_co_presenterships.where(presenter: @current_user.presenter).pending.present?

          if (immersive_invited && session.session_invited_immersive_participantships.where(participant: @current_user.participant).pending.where.not(blocking_notification_is_forcefully_closed_at: nil).present?) ||
             (livestream_invited && session.session_invited_livestream_participantships.where(participant: @current_user.participant).pending.where.not(blocking_notification_is_forcefully_closed_at: nil).present?) ||
             (invited_as_co_presenter && session.session_invited_immersive_co_presenterships.where(presenter: @current_user.presenter).pending.where.not(blocking_notification_is_forcefully_closed_at: nil).present?)
            return false
          end

          has_obtain_ability = @ability.can?(:obtain_free_trial_immersive_access, session) ||
                               @ability.can?(:purchase_immersive_access, session) ||
                               @ability.can?(:obtain_immersive_access_to_free_session, session) ||
                               @ability.can?(:obtain_free_trial_livestream_access, session) ||
                               @ability.can?(:purchase_livestream_access, session) ||
                               @ability.can?(:obtain_livestream_access_to_free_session, session)

          unless has_obtain_ability
            # Airbrake.notify(InvitedUserObtainAbilityMismatchError.new(model_invited_to: session, current_user: @current_user),
            #                 parameters: {
            #                   session: session.inspect,
            #                   current_user: @current_user.inspect,
            #                   participant_id: @current_user.participant_id.inspect,
            #                   session_participations: session.session_participations.inspect,
            #                   livestreamers: session.livestreamers.inspect
            #                 })
            @current_user.touch # force cache invalidation to see if it fixes the issue
            return false
          end

          true
        when Channel, Organization
          true
        else
          raise "can not interpret #{model_invited_to.self}"
        end
      end.call
    end
  end

  private

  # @return[ActiveRecord::Base]
  def pending_user_invites
    participant_id = @current_user&.participant_id || -1

    presenter_id = @current_user&.presenter_id || -1

    values = Rails.cache.fetch("pending_user_invites/#{@current_user.cache_key}") do
      result = ActiveRecord::Base.connection.execute <<EOL
        SELECT sessions.id, 'Session' as type, sessions.created_at as time_sortable_field FROM "sessions" LEFT OUTER JOIN channels ON channels.id = sessions.channel_id
          WHERE sessions.cancelled_at IS NULL
            AND sessions.status = 'published'
            AND (now() < (sessions.start_at + (INTERVAL '1 minute' * sessions.duration)))
            AND (
              sessions.id IN(SELECT session_id FROM session_invited_immersive_participantships WHERE participant_id = #{participant_id} AND status = 'pending')
                OR sessions.id IN(SELECT session_id FROM session_invited_livestream_participantships WHERE participant_id = #{participant_id} AND status = 'pending')
                OR sessions.id IN(SELECT session_id FROM session_invited_immersive_co_presenterships WHERE presenter_id = #{presenter_id} AND status = 'pending')
            )
        UNION ALL
        SELECT channels.id, 'Channel' as type, channels.created_at as time_sortable_field FROM channels
          JOIN channel_invited_presenterships ON channel_invited_presenterships.channel_id = channels.id
          WHERE channels.id IN (SELECT channel_id FROM channel_invited_presenterships WHERE presenter_id = #{presenter_id} AND status = 'pending')
        UNION ALL
        SELECT organizations.id, 'Organization' as type, organization_memberships.created_at as time_sortable_field FROM organizations
          JOIN organization_memberships ON organization_memberships.organization_id = organizations.id
          WHERE organization_memberships.status = 'pending' AND organization_memberships.user_id = #{@current_user.id}
        ORDER BY time_sortable_field DESC
EOL

      result.values
    end
    # values
    #=> [["576", "Session", "2015-12-29 22:26:56.362306"]]

    session_ids = values.select { |arr| arr[1] == 'Session' }.collect(&:first)
    channel_ids = values.select { |arr| arr[1] == 'Channel' }.collect(&:first)
    organization_ids = values.select { |arr| arr[1] == 'Organization' }.collect(&:first)

    pending_user_invites = []
    pending_user_invites.push(Session.where(id: session_ids)) if session_ids.present?
    pending_user_invites.push(Channel.approved.where(id: channel_ids)) if channel_ids.present?
    pending_user_invites.push(Organization.where(id: organization_ids)) if organization_ids.present?
    pending_user_invites.flatten.compact
  end
end
