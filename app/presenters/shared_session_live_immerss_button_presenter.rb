# frozen_string_literal: true

class SharedSessionLiveImmerssButtonPresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  # @param session - instance of Session class
  # @param current_user  - instance of User class
  #       variable needed for search results page(depending on which delivery type is chosen -
  #       live of vod, it displays different purchase options which has not to match)
  def initialize(session, current_user, current_ability)
    @session                       = session
    @current_user                  = current_user
    @current_ability               = current_ability

    @immersive_interactor  = ObtainImmersiveAccessToSession.new(session, current_user)
    @livestream_interactor = ObtainLivestreamAccessToSession.new(session, current_user)

    @immersive_links  = []
    @livestream_links = []
  end

  def to_s
    if @current_ability.can?(:opt_out_as_immersive_participant,
                             @session) || @current_ability.can?(:opt_out_as_livestream_participant, @session)
      return <<EOL
      <a class="immerssMeButton purchased" style="cursor: default" data-toggle='dropdown'>
        #{@session.immersive_purchase_price.zero? ? I18n.t('sessions.subscribed') : I18n.t('sessions.purchased')}
      </a>
EOL
             .html_safe
    end

    if !@immersive_interactor.could_be_obtained_and_not_pending_invitee? \
      && !@livestream_interactor.could_be_obtained_and_not_pending_invitee?

      return '<a class="nonActive" style="color: red"></a>'.html_safe
    end

    result = <<EOL
    <a class="immerssMeButton dropdown-toggle" data-toggle='dropdown'>
      #{Rails.application.credentials.global[:service_name]}
      <b class="caret-new" style="display:none">
        <i class="VideoClientIcon-angle-downF"></i>
        <i class="VideoClientIcon-angle-upF" style="display:none"></i>
      </b>
    </a>
    <a class="immerssMeButton OnlyFree dropdown-toggle" style="display:none" data-toggle='dropdown'>
      Free
      <b class="caret-new" style="display:none">
        <i class="VideoClientIcon-angle-downF"></i>
        <i class="VideoClientIcon-angle-upF" style="display:none"></i>
      </b>
    </a>
    <ul class="dropdown-menu pull-right">
EOL
             .html_safe
    prepare_links

    if @immersive_links.present?
      result += <<EOL
      <div class='imWrapp'>
        <div class='imTitle'>
          Immersive
        </div>
EOL
                .html_safe

      @immersive_links.each do |link|
        result += "<div class='imPrice'> #{link} </div>".html_safe
      end

      result += '</div>'.html_safe
    end

    if @livestream_links.present?
      result += <<EOL
      <div class='imWrapp'>
        <div class='imTitle'>
          Livestream
        </div>
EOL
                .html_safe

      @livestream_links.each do |link|
        result += "<div class='imPrice'> #{link} </div>".html_safe
      end

      result += '</div>'.html_safe
    end

    result + '</ul>'.html_safe
  end

  private

  def user_signed_in?
    @current_user.present?
  end

  def prepare_links
    if @immersive_interactor.could_be_obtained_and_not_pending_invitee?
      if @immersive_interactor.can_have_free_trial?
        @immersive_links << degradable_link_to('Free Trial',
                                               preview_purchase_channel_session_path(@session.slug,
                                                                                     type: ObtainTypes::FREE_IMMERSIVE),
                                               remote: true,
                                               style: '')
      end

      if @immersive_interactor.can_take_for_free?
        @immersive_links << degradable_link_to(I18n.t('sessions.subscribe'),
                                               preview_purchase_channel_session_path(@session.slug,
                                                                                     type: ObtainTypes::FREE_IMMERSIVE),
                                               remote: true,
                                               style: '')
      end
      if @immersive_interactor.could_be_purchased?
        @immersive_links << degradable_link_to(@immersive_interactor.obtain_non_free_access_title,
                                               preview_purchase_channel_session_path(@session.slug,
                                                                                     type: ObtainTypes::PAID_IMMERSIVE),
                                               remote: true,
                                               style: '')
      end
    end

    if @livestream_interactor.could_be_obtained_and_not_pending_invitee?
      if @livestream_interactor.can_have_free_trial?
        @livestream_links << degradable_link_to('Free Trial',
                                                preview_purchase_channel_session_path(@session.slug,
                                                                                      type: ObtainTypes::FREE_LIVESTREAM),
                                                remote: true,
                                                style: '')
      end

      if @livestream_interactor.can_take_for_free?
        @livestream_links << degradable_link_to(I18n.t('sessions.subscribe'),
                                                preview_purchase_channel_session_path(@session.slug,
                                                                                      type: ObtainTypes::FREE_LIVESTREAM),
                                                remote: true,
                                                style: '')
      end
      if @livestream_interactor.could_be_purchased?
        @livestream_links << degradable_link_to(@livestream_interactor.obtain_non_free_access_title,
                                                preview_purchase_channel_session_path(@session.slug,
                                                                                      type: ObtainTypes::PAID_LIVESTREAM),
                                                remote: true,
                                                style: '')
      end
    end
  end
end
