# frozen_string_literal: true

module LobbiesHelper
  def display_donations_tab?
    return true if @abstract_session.is_a?(Session) && @abstract_session.donate_video_tab_content_in_markdown_format.present?

    false
  end

  def donate_title_as_singular
    @abstract_session.donate_title_as_singular or raise
  end

  # NOTE: important here is to return without "$" in result numbers
  #      dollar sign is appended where neccessary in backbone template
  def donate_options
    @abstract_session.donate_video_tab_options_in_csv_format.parse_csv.collect(&:strip).collect do |num|
      number_to_currency(num, precision: 2, unit: '')
    end
  end

  def paypal_item_number
    PaypalUtils.paypal_number(user_id: current_user.id, abstract_session: @abstract_session)
  end

  def paypal_item_name
    case donate_title_as_singular
    when PaypalDonation::TitleAsSingular::DONATE
      "Donation to user #{@abstract_session.organizer.full_name}"
    when PaypalDonation::TitleAsSingular::TIP
      "Tip to user #{@abstract_session.organizer.full_name}"
    when PaypalDonation::TitleAsSingular::GIFT
      "Gift to user #{@abstract_session.organizer.full_name}"
    else
      notify_airbrake(RuntimeError.new('unknown donate title'),
                      parameters: {
                        value: @abstract_session.donate_title_as_singular,
                        abstract_session_type: @abstract_session.class.to_s,
                        abstract_session_id: @abstract_session.id
                      })
      "Donation to user #{@abstract_session.organizer.full_name}"
    end
  end

  def can_make_donations?
    return [true, false].sample if Rails.env.development?

    @abstract_session.organizer != current_user
  end

  def show_webrtc?
    if browser.platform.windows?
      return false if browser.ie?
      return false if browser.safari?
    elsif browser.platform.mac?
      return false if browser.safari?
    end
    true
  end

  def display_twitter_feed_in_video_client?
    @abstract_session.is_a?(Session) && @abstract_session.twitter_feed_title.present?
  end

  def donate_video_tab_content(abstract_session)
    Rails.cache.fetch("#{__method__}/#{abstract_session.cache_key}") do
      _raw = if abstract_session.respond_to?(:donate_video_tab_content_in_markdown_format)
               abstract_session.donate_video_tab_content_in_markdown_format
             else
               raise "you shouldnt be calling this method in the first place for #{abstract_session.class}, id #{abstract_session.id}"
             end

      html = Markdown.new(_raw).to_html
      doc = Nokogiri::HTML.fragment(html)
      doc.css('a').each do |a|
        a.set_attribute('target', '_blank')
      end
      doc.to_s.html_safe
    end
  end

  def display_paypal_donation_options?
    return true if Rails.env.development?

    @abstract_session.is_a?(Session) && @abstract_session.organizer != current_user
  end

  def is_owner?
    @role == 'presenter'
  end

  def is_organizer?
    @abstract_session.organizer == current_user
  end

  def has_control?
    @room.room_members.find_by(abstract_user: current_user).try(:has_control) || @role == 'presenter'
  end

  def is_myself?(user)
    user == current_user
  end

  def visible?(condition)
    'display:none;' unless condition
  end

  def is_participant?
    @role == 'participant'
  end

  def can_ask_question?
    is_participant? and @abstract_session.is_a?(Session)
  end

  def banned?(user)
    @room.room_members.banned.exists?(abstract_user: user)
  end

  def disable_if_banned_or_not_joined(user)
    # if banned?(user) or !@room.room_members.where(abstract_user_id: user.id).exists?
    #   'disabled'
    # end
  end

  def disabled_if_no_question(user)
    'disabled' unless user.try(:has_questions?, @abstract_session.id)
  end

  def active_if_has_question(user)
    'active' if user.try(:has_questions?, @abstract_session.id)
  end

  def video_player_enabled?
    @abstract_session.is_a?(Session) && controller_name != 'livestreams'
  end

  def state_class
    if @room.active?
      :live
    elsif @room.room_members.exists?(backstage: true)
      :GreenRoom
    else
      :offAir
    end
  end

  def social_class(provider)
    case provider
    when SocialLink::Providers::YOUTUBE
      { i_class: 'VideoClientIcon-youtube', a_class: 'social-youtube' }
    when SocialLink::Providers::INSTAGRAM
      { i_class: 'VideoClientIcon-instagram', a_class: 'social-instagram' }
    when SocialLink::Providers::FACEBOOK
      { i_class: 'VideoClientIcon-facebookF', a_class: 'social-f' }
    when SocialLink::Providers::TWITTER
      { i_class: 'VideoClientIcon-twitter2', a_class: 'social-tw' }
    when SocialLink::Providers::GPLUS
      { i_class: 'VideoClientIcon-google', a_class: 'social-g' }
    when SocialLink::Providers::LINKEDIN
      { i_class: 'VideoClientIcon-linkedin', a_class: 'social-f' }
    else
      { i_class: 'VideoClientIcon-web', a_class: 'social-f' }
    end
  end

  def color_by_status(status)
    case status
    when FfmpegserviceAccount::Statuses::UP
      'green'
    when FfmpegserviceAccount::Statuses::DOWN, FfmpegserviceAccount::Statuses::STARTING
      'yellow'
    else
      'red'
    end
  end

  def text_by_status(status)
    case status
    when FfmpegserviceAccount::Statuses::UP
      'OK'
    when FfmpegserviceAccount::Statuses::DOWN
      'Please turn on the stream.'
    when FfmpegserviceAccount::Statuses::STARTING
      'Initialization stream server, please wait.'
    else
      'Stream server was stopped, please click by reload button.'
    end
  end
end
