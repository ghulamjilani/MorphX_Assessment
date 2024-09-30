# frozen_string_literal: true

class SharedSessionVodImmerssButtonPresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  include MoneyHelper

  # @param session - instance of Session class
  # @param current_user  - instance of User class
  #       variable needed for search results page(depending on which delivery type is chosen -
  #       live of vod, it displays different purchase options which has not to match)
  # @param video - instance of Video class
  #       used at VIDEO ON DEMAND section so the price on Paid VoD and free on free vod are just label,
  #       by click on them you just link to channel-session page
  def initialize(session, current_user, current_ability, video = nil)
    @session         = session
    @current_user    = current_user
    @current_ability = current_ability
    @video           = video
    @video_url       = "#{@session.relative_path}?video_id=#{@video.try(:id)}"

    @recorded_interactor = ObtainRecordedAccessToSession.new(session, current_user)

    @recorded_links = []
  end

  def to_s
    if @current_ability.can?(:opt_out_as_recorded_member, @session)
      return <<EOL
      <a href="#{@video ? @video_url : ''}" class="immerssMeButton purchased">
        #{@session.recorded_purchase_price&.zero? ? I18n.t('sessions.subscribed') : I18n.t('sessions.purchased')}
      </a>
EOL
             .html_safe
    end

    if !@recorded_interactor.could_be_obtained?
      # Trying to catch Heisenbug
      if @current_user != @session.organizer
        # NOTE: for non-organizers vod tile must be in one of the 3 states - "purchased"/"Buy"/"Free"
        Airbrake.notify(RuntimeError.new('find out why that session is vod-unobtainable'),
                        parameters: {
                          session: @session.inspect,
                          current_user: @current_user.inspect
                        })
      else
        return %(<a href="#{@video ? @video_url : ''}" class="immerssMeButton grey"> #{as_currency(
          @session.recorded_purchase_price, @current_user
        )}</a>).html_safe
      end
      # Trying to catch Heisenbug

      return '<a class="nonActive" style="color: red"></a>'.html_safe
    elsif @recorded_interactor.could_be_purchased?
      degradable_link_to(as_currency(@session.recorded_purchase_price, @current_user),
                         if @video
                           @video_url
                         else
                           preview_purchase_channel_session_path(@session.slug,
                                                                 type: ObtainTypes::PAID_VOD)
                         end,
                         title: @recorded_interactor.obtain_non_free_access_title,
                         class: 'immerssMeButton grey')
    else
      degradable_link_to('Free',
                         if @video
                           @video_url
                         else
                           preview_purchase_channel_session_path(@session.slug,
                                                                 type: ObtainTypes::FREE_VOD)
                         end,
                         class: 'immerssMeButton onlyFree grey')

    end
  end

  private

  def user_signed_in?
    @current_user.present?
  end
end
