# frozen_string_literal: true

module ProfilesHelper
  REPLENISH_MODAL = 'replenish'

  # @return [String]
  def confirmed_phone_numbers(user)
    return [] if user.blank?

    user.authy_records.where(status: AuthyRecord::Statuses::APPROVED).collect do |ar|
      "+#{ar.country_code}#{ar.cellphone}"
    end
  end

  def display_phone_number_verification_link?
    return false if current_user.user_account.phone.blank?

    !current_user.current_phone_is_approved?
  end

  def current_user_never_gave_us_email_that_we_saved?
    if current_user.email_changed? && current_user.changes[:email].present? && current_user.changes[:email].first.blank?
      return true
    end

    if !request.get? && current_user.errors[:email].present? # no need to highlight "can't be blank" first time you open that form
      # NOTE: it is already validated in controller
      return true
    end

    # NOTE: first time user sets email, it is writter to #email and not to #unconfirmed_email - that's why
    current_user.email.blank? # could be like Twitter user until email was given
  end

  def social_link_label_for(provider)
    case provider
    when SocialLink::Providers::YOUTUBE
      content_tag :div do
        concat(content_tag(:span, 'Youtube', class: 'socialLinks'))
        concat(content_tag(:i, '', class: 'VideoClientIcon-youtube'))
      end
    when SocialLink::Providers::TELEGRAM
      content_tag :div do
        concat(content_tag(:span, 'Telegram', class: 'socialLinks'))
        concat(content_tag(:i, '', class: 'GlobalIcon-telegram'))
      end
    when SocialLink::Providers::INSTAGRAM
      content_tag :div do
        concat(content_tag(:span, 'Instagram', class: 'socialLinks'))
        concat(content_tag(:i, '', class: 'VideoClientIcon-instagram'))
      end
    when SocialLink::Providers::FACEBOOK
      content_tag :div do
        concat(content_tag(:span, 'Facebook', class: 'socialLinks'))
        concat(content_tag(:i, '', class: 'VideoClientIcon-facebookF'))
      end
    when SocialLink::Providers::TWITTER
      content_tag :div do
        concat(content_tag(:span, 'Twitter', class: 'socialLinks'))
        concat(content_tag(:i, '', class: 'VideoClientIcon-twitter2'))
      end
    when SocialLink::Providers::GPLUS
      content_tag :div do
        concat(content_tag(:span, 'Google', class: 'socialLinks'))
        concat(content_tag(:i, '', class: 'VideoClientIcon-google'))
      end
    when SocialLink::Providers::LINKEDIN
      content_tag :div do
        concat(content_tag(:span, 'LinkedIn', class: 'socialLinks'))
        concat(content_tag(:i, '', class: 'VideoClientIcon-linkedinF'))
      end
    when SocialLink::Providers::EXPLICIT
      content_tag :div do
        concat(content_tag(:span, 'My Site', class: 'socialLinks'))
        concat(content_tag(:i, '', class: 'VideoClientIcon-globeF'))
      end
    else
      raise "can not interpet #{provider}"
    end
  end

  def org_social_link_icon_for(provider)
    case provider
    when SocialLink::Providers::YOUTUBE, SocialLink::Providers::TELEGRAM, SocialLink::Providers::INSTAGRAM, SocialLink::Providers::EXPLICIT
      content_tag(:i, class: 'VideoClientIcon-web') { '' }
    when SocialLink::Providers::FACEBOOK
      content_tag(:i, class: 'VideoClientIcon-facebook_2') { '' }
    when SocialLink::Providers::TWITTER
      content_tag(:i, class: 'VideoClientIcon-twitter_2') { '' }
    when SocialLink::Providers::GPLUS
      content_tag(:i, class: 'VideoClientIcon-google3') { '' }
    when SocialLink::Providers::LINKEDIN
      content_tag(:i, class: 'VideoClientIcon-linkedin_2') { '' }
    else
      raise "can not interpet #{provider}"
    end
  end

  def edit_credit_card_button_onclick
    %(alert("#{I18n.t('braintree.ui.detach_cc_to_edit')}"); return false)
  end
end
