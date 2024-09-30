# frozen_string_literal: true

class SessionInvitationButtonsPresenter < AbstractSessionInvitationButtonsPresenter
  def initialize(options)
    super(options)

    @model_invited_to = options[:model_invited_to]
    @current_user     = options[:current_user]
    @ability          = options[:ability]

    @immersive_links  = []
    @livestream_links = []

    @immersive_invited = @current_user.present? \
      && @current_user.participant.present? \
      && session.session_invited_immersive_participantships.where(participant: @current_user.participant).pending.present?

    @livestream_invited = @current_user.present? \
      && @current_user.participant.present? \
      && session.session_invited_livestream_participantships.where(participant: @current_user.participant).pending.present?

    @invited_as_co_presenter = @current_user.present? \
      && @current_user.presenter.present? \
      && session.session_invited_immersive_co_presenterships.where(presenter: @current_user.presenter).pending.present?
  end

  # NOTE: this method is used only in dashboard templates
  def to_s_for_dashboard
    unless @ability.can?(:accept_or_reject_invitation, session)
      return ''
    end

    before_to_s

    <<EOL
      <div class='btns-group full-width'>
        #{accept_html('btn btn-m full-width btn-green')}
        #{link_to(reject_invitation_session_path(session.id),
                  class: 'btn full-width btn-m btn-secondary',
                  data: { disable_with: 'Please wait…' },
                  method: :post) { '<i class="GlobalIcon-clear"></i> No, thanks'.html_safe }}
      </div>
EOL
  rescue InvitedUserObtainAbilityMismatchError => e
    Airbrake.notify(e,
                    parameters: {
                      session: e.model_invited_to.inspect,
                      current_user: e.current_user.inspect,
                      participant_id: e.current_user.participant_id.inspect,
                      session_participations: session.session_participations.inspect,
                      livestreamers: session.livestreamers.inspect
                    })
    ''
  end

  def to_s_for_tile
    unless @ability.can?(:accept_or_reject_invitation, session)
      return ''
    end

    before_to_s

    _accept_html = if display_accept_button_as_link?
                     link_to('I accept',
                             accept_invitation_session_path(session.id),
                             title: 'Accept invitation',
                             class: 'AcceptBTN remAcceptDeclineBlock',
                             method: :post)
                   else
                     link_to('I accept',
                             sessions_preview_accept_invitation_modal_path(session.id),
                             title: 'Accept Invitation',
                             method: :get,
                             class: 'AcceptBTN remAcceptDeclineBlock',
                             remote: true)
                   end

    <<EOL
      <div class='acceptDeclineBlock'>
        #{_accept_html}
        #{link_to(reject_invitation_session_path(session.id),
                  class: 'DeclineBTN remAcceptDeclineBlock',
                  data: { disable_with: 'Please wait…' },
                  method: :post) { '<i class="GlobalIcon-clear"></i> No, thanks'.html_safe }}
      </div>
EOL
  rescue InvitedUserObtainAbilityMismatchError => e
    Airbrake.notify(e,
                    parameters: {
                      session: e.model_invited_to.inspect,
                      current_user: e.current_user.inspect,
                      participant_id: e.current_user.participant_id.inspect,
                      session_participations: session.session_participations.inspect,
                      livestreamers: session.livestreamers.inspect
                    })
    ''
  end

  # NOTE: it must be public
  attr_reader :immersive_links

  # NOTE: it must be public
  attr_reader :livestream_links

  # NOTE: it must be public
  def prepare_obtain_links
    if @ability.can?(:obtain_immersive_access_to_free_session, session)
      @immersive_links << link_to(I18n.t('sessions.subscribe'),
                                  preview_purchase_channel_session_path(session.slug,
                                                                        type: ObtainTypes::FREE_IMMERSIVE),
                                  remote: true,
                                  class: 'btn btn-m margin-top-10',
                                  style: 'font-size: 14px').html_safe
    else
      if @ability.can?(:obtain_free_trial_immersive_access, session)
        @immersive_links << link_to('Free Trial',
                                    preview_purchase_channel_session_path(session.slug,
                                                                          type: ObtainTypes::FREE_IMMERSIVE),
                                    remote: true,
                                    class: 'btn btn-m margin-top-10',
                                    style: 'font-size: 14px').html_safe
      end

      if @ability.can?(:purchase_immersive_access, session)
        interactor1 = ObtainImmersiveAccessToSession.new(session, @current_user)

        @immersive_links << link_to("Buy for #{as_currency interactor1.charge_amount, @current_user}",
                                    preview_purchase_channel_session_path(session.slug,
                                                                          type: ObtainTypes::PAID_IMMERSIVE),
                                    remote: true,
                                    class: 'btn btn-m',
                                    style: 'font-size: 14px').html_safe
      end
    end

    if @ability.can?(:obtain_livestream_access_to_free_session, session)
      @livestream_links << link_to(I18n.t('sessions.subscribe'),
                                   preview_purchase_channel_session_path(session.slug,
                                                                         type: ObtainTypes::FREE_LIVESTREAM),
                                   class: 'btn btn-m margin-top-10',
                                   remote: true,
                                   style: 'font-size: 14px').html_safe
    else
      if @ability.can?(:obtain_free_trial_livestream_access, session)
        @livestream_links << link_to('Free Trial',
                                     preview_purchase_channel_session_path(session.slug,
                                                                           type: ObtainTypes::FREE_LIVESTREAM),
                                     class: 'btn btn-m margin-top-10',
                                     remote: true,
                                     style: 'font-size: 14px').html_safe
      end

      if @ability.can?(:purchase_livestream_access, session)
        charge_amount = session.livestream_purchase_price
        @livestream_links << link_to("Buy for #{as_currency charge_amount, @current_user}",
                                     preview_purchase_channel_session_path(session.slug,
                                                                           type: ObtainTypes::PAID_LIVESTREAM),
                                     class: 'btn btn-m',
                                     remote: true,
                                     style: 'font-size: 14px').html_safe
      end
    end
  end

  def forcefully_close_path
    if @invited_as_co_presenter || @immersive_invited
      Rails.application.class.routes.url_helpers.forcefully_close_session_invited_immersive_participantships_path(session_id: session.id)
    elsif @livestream_invited
      Rails.application.class.routes.url_helpers.forcefully_close_session_invited_livestream_participantships_path(session_id: session.id)
    else
      "can not interpret - #{@current_user} #{session}"
    end
  end

  def invite_message_title
    if @invited_as_co_presenter
      %(You are invited to participate in "#{session.always_present_title}" session as co-presenter.)
    elsif @immersive_invited && @livestream_invited
      %(You are invited to participate in "#{session.always_present_title}" session.)
    elsif @immersive_invited
      %(You are invited to participate in "#{session.always_present_title}" session as immersive participant.)
    elsif @livestream_invited
      %(You are invited to participate in "#{session.always_present_title}" session as livestream participant.)
    else
      "can not interpret - #{@current_user} #{session}"
    end
  end

  def before_to_s
    has_obtain_ability = @ability.can?(:obtain_free_trial_immersive_access, session) ||
                         @ability.can?(:purchase_immersive_access, session) ||
                         @ability.can?(:obtain_immersive_access_to_free_session, session) ||
                         @ability.can?(:obtain_free_trial_livestream_access, session) ||
                         @ability.can?(:purchase_livestream_access, session) ||
                         @ability.can?(:obtain_livestream_access_to_free_session, session)

    unless has_obtain_ability
      InvitedUserObtainAbilityMismatchError.new(model_invited_to: session, current_user: @current_user)
    end

    prepare_obtain_links
  end

  def session
    @model_invited_to
  end

  def title
    session.title
  end

  def message
    presenter_link = %(<a target="_blank" href="#{session.organizer.absolute_path}">#{session.organizer.full_name}</a>)
    session_link   = %(<a target="_blank" href="#{session.absolute_path}">a session</a>)

    if @invited_as_co_presenter
      I18n.t('presenters.session_invitation_buttons_presenter.invited_you_to_participate', presenter_link: presenter_link, session_link: session_link, creator: I18n.t('dictionary.creator'))
    elsif @immersive_invited && @livestream_invited
      %(#{presenter_link} invited you to participate in #{session_link}.)
    elsif @immersive_invited
      %(#{presenter_link} invited you to participate in #{session_link} as participant.)
    elsif @livestream_invited
      %(#{presenter_link} invited you to view #{session_link} as viewer.)
    else
      # Airbrake.notify("can not interpret - #{@current_user} #{session}")
      "can not interpret - #{@current_user} #{session}"
    end
  end

  # NOTE: - this method is also used separately(without #to_s method)
  def accept_html(class_attribute = nil)
    class_attribute = ([class_attribute] + ['active']).compact.join(' ')
    if @immersive_links.blank? && @livestream_links.blank?
      prepare_obtain_links
    end

    if display_accept_button_as_link?
      accept_html_as_link(class_attribute)
    else
      accept_html_modal_window_with_choice(class_attribute)
    end
  end

  def decline_html(class_attribute = nil)
    link_to('No, thanks', reject_invitation_session_path(session.id),
            class: ['btn btn-s btn-secondary', class_attribute].compact.join(' '),
            method: :post)
  end

  private

  def display_accept_button_as_link?
    if @invited_as_co_presenter || (@immersive_invited && @livestream_invited)
      (@immersive_links.size + @livestream_links.size) < 2
    elsif @immersive_invited || @livestream_invited
      (@immersive_links.size) < 2
    else
      # Airbrake.notify("can not interpret")
      true
    end
  end

  def accept_html_as_link(class_attribute)
    link_to(accept_invitation_session_path(session.id),
            class: "btn btn-s #{class_attribute}",
            method: :post) { 'I accept'.html_safe }
  end

  def accept_html_modal_window_with_choice(class_attribute)
    link_to(sessions_preview_accept_invitation_modal_path(session.id),
            title: 'Accept Invitation',
            method: :get,
            class: class_attribute,
            remote: true) { '<i class="VideoClientIcon-checkmark"></i> I accept'.html_safe }
  end
end
