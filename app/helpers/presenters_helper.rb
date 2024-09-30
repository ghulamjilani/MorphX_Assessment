# frozen_string_literal: true

module PresentersHelper
  def available_on_vod_request_is_visible?
    return true if controller_name == 'presenter_steps'

    already_became_a_presenter = current_user.user_account.tagline.present?
    controller_name == 'profiles' && already_became_a_presenter
  end

  # NOTE: purpose of this method is to send user to exact presenter_steps' step
  # if user never applied as presenter - then it is 1st step
  # if user dropped at last step(channel creation) - then send him to this last 3rd step
  def work_with_us_link
    unless user_signed_in?
      return Rails.application.class.routes.url_helpers.landing_home_path
    end

    step = current_user.presenter.try(:last_seen_become_presenter_step)
    case step
    when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP2
      Rails.application.class.routes.url_helpers.wizard_v2_business_path
    when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP3
      Rails.application.class.routes.url_helpers.wizard_v2_channel_path
    when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::DONE
      Rails.application.class.routes.url_helpers.wizard_v2_summary_path
    else
      Rails.application.class.routes.url_helpers.landing_home_path
    end
  end

  def work_with_us_title
    return 'START CREATING' unless user_signed_in?

    step = current_user.presenter.try(:last_seen_become_presenter_step)
    case step
    when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP2
      'Complete Business'
    when Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP3
      'Complete Channel'
    else
      'START CREATING'
    end
  end

  # otherwise it may to hard-to-debug exceptions and user may get stuck
  def create_channel_is_clickabled?
    user_signed_in? \
      && current_user.presenter.present? \
      && current_user.user_account.present? \
      && current_user.user_account.tagline.present? \
      && current_user.user_account.bio.present? \
      && current_user.presenter.channels.count.zero?
  end

  # FIXME: refactor!!!
  def vanilla_follow_link(user, css_class = '', styles = '')
    if user_signed_in?
      if current_ability.can?(:follow, user)
        text = current_user.fast_following?(user) ? 'Following' : 'Follow'

        link_to(text, user.toggle_follow_relative_path, method: :post, class: css_class, remote: true, style: styles)
      else
        link_to('Follow', '#', class: "disabled #{css_class}", onclick: 'return: false;', rel: 'tipsy',
                               title: 'You cant follow yourself.', style: "pointer-events: auto;#{styles}")
      end
    else
      degradable_link_to('Follow', user.toggle_follow_relative_path, method: :post, class: css_class, remote: true,
                                                                     style: styles)
    end
  end

  def rich_follow_link(user, css_class = 'FllBTN', &block)
    if user_signed_in?
      if current_ability.can?(:follow, user)
        following = current_user.fast_following?(user)
        text = following ? 'Following' : 'Follow'

        link_to(user.toggle_follow_relative_path, method: :post, class: "#{css_class} #{'active' if following}",
                                                  remote: true) do
          "#{capture_haml(&block)} #{text}".html_safe
        end
      else
        ''
      end
    else
      degradable_link_to(user.toggle_follow_relative_path, method: :post, class: css_class, remote: true) do
        "#{capture_haml(&block)} Follow".html_safe
      end
    end
  end

  def instructional_channel_type_input(channel)
    attrs = { name: 'channel[channel_type_id]', type: 'radio', value: Channel.instructional_type_id }.tap do |result|
      if channel.new_record? || channel.instructional_type?
        result[:checked] = true
      end

      if channel.sessions.present?
        result[:disabled] = true
        result[:readonly] = true
      end
    end

    content_tag :input, '', attrs
  end

  def performance_channel_type_input(channel)
    attrs = { name: 'channel[channel_type_id]', type: 'radio', value: Channel.performance_type_id }.tap do |result|
      if !channel.new_record? && channel.performance_type?
        result[:checked] = true
      end

      if channel.sessions.present?
        result[:disabled] = true
        result[:readonly] = true
      end
    end

    content_tag :input, '', attrs
  end

  def social_channel_type_input(channel)
    attrs = { name: 'channel[channel_type_id]', type: 'radio', value: Channel.social_type_id }.tap do |result|
      if !channel.new_record? && channel.social_type?
        result[:checked] = true
      end

      if channel.sessions.present?
        result[:disabled] = true
        result[:readonly] = true
      end
    end

    content_tag :input, '', attrs
  end
end
