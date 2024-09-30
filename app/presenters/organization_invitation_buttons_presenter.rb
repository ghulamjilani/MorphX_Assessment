# frozen_string_literal: true

class OrganizationInvitationButtonsPresenter < AbstractSessionInvitationButtonsPresenter
  def initialize(options)
    super(options)

    @model_invited_to = options[:model_invited_to]
    @current_user     = options[:current_user]
    @ability          = options[:ability]

    @immersive_links = []
  end

  # NOTE: this method is used only in dashboard templates
  def to_s_for_dashboard
    unless @ability.can?(:accept_or_reject_invitation, organization)
      return ''
    end

    <<EOL
      <div class='btns-group full-width'>
        #{accept_html('btn btn-m full-width btn-green')}
        #{link_to(reject_invitation_organization_path(organization.id),
                  class: 'btn full-width btn-m btn-borderred-secondary',
                  data: { disable_with: 'Please wait…' },
                  method: :post) { '<i class="GlobalIcon-clear"></i> No, thanks'.html_safe }}
      </div>
EOL
  rescue InvitedUserObtainAbilityMismatchError => e
    Airbrake.notify(e,
                    parameters: {
                      organization: e.model_invited_to.inspect,
                      current_user: e.current_user.inspect,
                      presenter_id: e.current_user.presenter.id.inspect,
                      user_pending_memberships: e.current_user.organization_memberships_participants.pending.inspect
                    })
    ''
  end

  def title
    organization.title
  end

  def message
    company_link = %(<span><a target="_blank" href="#{organization.absolute_path}">#{organization.title}</a></span>)
    I18n.t('notifications.organization.invite_as_member', company_name: company_link)
  end

  def forcefully_close_path
    nil
  end

  def accept_html(class_attribute = nil)
    class_attribute = ([class_attribute] + ['active']).compact.join(' ')

    accept_html_as_link(class_attribute)
  end

  def decline_html(class_attribute = nil)
    link_to(reject_invitation_organization_path(organization.id),
            class: class_attribute,
            method: :post) { '<i class="GlobalIcon-clear"></i> No, thanks'.html_safe }
  end

  private

  def accept_html_as_link(class_attribute)
    link_to(accept_invitation_organization_path(organization.id),
            class: class_attribute,
            method: :post) { '<i class="VideoClientIcon-checkmark"></i> I accept'.html_safe }
  end

  def organization
    @model_invited_to
  end
end
