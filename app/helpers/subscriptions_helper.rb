# frozen_string_literal: true

module SubscriptionsHelper
  def select_channel_option_text(channel)
    result = channel.title
    if !channel.listed?
      result += ' - This channel is unlisted, please make it listed first.'
    elsif channel.subscription.present?
      result += ' - This channel already has a subscription.'
    end
    result
  end

  def select_channel_option_attributes(channel)
    {
      'data-is-listed': channel.listed?,
      'data-is-subscription-present': channel.subscription.present?,
      'disabled': !channel.listed? || channel.subscription.present?
    }
  end
end
