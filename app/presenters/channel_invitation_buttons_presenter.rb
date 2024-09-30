# frozen_string_literal: true

class ChannelInvitationButtonsPresenter < AbstractSessionInvitationButtonsPresenter
  def initialize(options)
    super(options)

    @model_invited_to = options[:model_invited_to]
    @current_user     = options[:current_user]
    @ability          = options[:ability]

    @immersive_links = []
  end

  # NOTE: this method is used only in dashboard templates
  def to_s_for_dashboard
    unless @ability.can?(:accept_or_reject_invitation, channel)
      return ''
    end

    <<EOL
      <div class='btns-group full-width'>
        #{accept_html('btn btn-m full-width btn-green')}
        #{link_to(reject_invitation_channel_path(channel.id),
                  class: 'btn full-width btn-m btn-borderred-secondary',
                  data: { disable_with: 'Please wait…' },
                  method: :post) { '<i class="GlobalIcon-clear"></i> No, thanks'.html_safe }}
      </div>
EOL
  rescue InvitedUserObtainAbilityMismatchError => e
    Airbrake.notify(e,
                    parameters: {
                      channel: e.model_invited_to.inspect,
                      current_user: e.current_user.inspect,
                      presenter_id: e.current_user.presenter.id.inspect,
                      channel_invited_presenterships: channel.channel_invited_presenterships.inspect
                    })
    ''
  end

  def title
    channel.title
  end

  def message
    channel_link = %(<span><a target="_blank" href="#{channel.absolute_path}">#{channel.title}</a></span>)
    brand_link = %(<span><a target="_blank" href="#{(channel.organization || channel.organizer).absolute_path}">#{channel.organization&.name || channel.organizer.public_display_name}</a></span>)
    I18n.t('notifications.channel.invite_as_creator_popup', channel_name: channel_link, company_name: brand_link)
  end

  def forcefully_close_path
    Rails.application.class.routes.url_helpers.forcefully_close_channel_invited_participantships_path(channel_id: @model_invited_to.id)
  end

  def accept_html(class_attribute = nil)
    class_attribute = ([class_attribute] + ['active']).compact.join(' ')

    accept_html_as_link(class_attribute)
  end

  def decline_html(class_attribute = nil)
    link_to(reject_invitation_channel_path(channel.id),
            class: class_attribute,
            method: :post) { '<i class="GlobalIcon-clear"></i> No, thanks'.html_safe }
  end

  private

  def accept_html_as_link(class_attribute)
    link_to(accept_invitation_channel_path(channel.id),
            class: class_attribute,
            method: :post) { '<i class="VideoClientIcon-checkmark"></i> I accept'.html_safe }
  end

  def channel
    @model_invited_to
  end
end
