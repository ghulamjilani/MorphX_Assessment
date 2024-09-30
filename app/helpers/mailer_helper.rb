# frozen_string_literal: true

module MailerHelper
  include ApplicationHelper

  def absolute_path_for_user(model)
    raise '@user has to be present' if @user.blank?

    "#{model.absolute_path}?#{MAILER_USER_ID_PARAM}=#{@user.id}"
  end

  def merchant_name
    Rails.application.credentials.global[:host]
  end

  def email_direct_message_context(from_name)
    return unless from_name

    email_header_text(I18n.t('helpers.mailer.email_direct_message_context.direct_message_from', from_name: from_name))
  end

  def email_header_text(content)
    content_for(:email_header_text) do
      content
    end
  end

  def email_team_thank_you(team_name)
    return if team_name.blank?

    I18n.t('helpers.mailer.email_team_thank_you.message', team_name: team_name)
  end

  def cancelled_or_opted_out_reason_text(pending_refund)
    abstract_session = pending_refund.payment_transaction.purchased_item
    # TODO: - what if that was sys credit purchase instead? FIXME
    if abstract_session.cancelled?
      I18n.t('mailer.abstract_session_cancelled_by_organiser',
             url: abstract_session.absolute_path,
             title: abstract_session.always_present_title)
    else
      I18n.t('mailer.opted_out_from_abstract_session',
             url: abstract_session.absolute_path,
             title: abstract_session.always_present_title)
    end
  end

  def channel_key_title(raw_key)
    case raw_key
    when 'category_id'
      'Category'
    when 'channel_type_id'
      'Type'
    else
      raw_key.to_s.capitalize.titleize
    end
  end

  def channel_value_title(raw_key, value)
    case raw_key
    when 'category_id'
      ChannelCategory.find(value).name
    when 'channel_type_id'
      ChannelType.find(value).description
    else
      value
    end
  end

  # NOTE: this method has side effect
  #
  # @return [String]
  def generate_user_invitation_token_and_return!
    raise '@user must be present' if @user.blank?

    # partially imitating lib/devise_invitable/model.rb#deliver_invitation
    @user.send(:generate_invitation_token!)
    @user.update_attribute(:invitation_sent_at, Time.now.utc) unless @user.invitation_sent_at
    @user.raw_invitation_token or raise 'cant get raw/unencrypted invitation token'
  end

  def eligible_for_system_credit_refund?(pending_refund, current_user)
    session = pending_refund.abstract_session
    return true unless session.is_a?(Session)

    co_presenter_users = session.co_presenters.collect(&:user)
    co_presenter_users.exclude?(current_user)
  end

  def wrap_content_urls(content)
    content = Html::Parser.new(content).wrap_urls.to_s.html_safe
  end

  def perform_replacements(content, replacements)
    replacements.each do |needle, replacement|
      content.gsub!(needle, replacement)
    end
    content = content.html_safe
  end
end
