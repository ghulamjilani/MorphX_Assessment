# frozen_string_literal: true

module ChannelsHelper
  def full_calendar_events(channel)
    channel.sessions.where(cancelled_at: nil,
                           fake: false).published.for_user_with_age(current_user).collect(&:as_icecube_hash)
  end

  def channel_category_collection
    ChannelCategory.all.order(featured: :desc, name: :asc).collect do |c|
      title = c.description_in_markdown_format ? Markdown.new(c.description_in_markdown_format).to_html : c.name

      [
        c.name,
        c.id,
        { title: title }
      ]
    end
  end

  def channel_type_collection
    ChannelType.all.order(description: :asc).collect do |c|
      [
        c.description,
        c.id,
        { title: c.description }
      ]
    end
  end

  def channel_status(channel)
    return 'Archived' if channel.archived?

    case channel.status
    when Channel::Statuses::DRAFT
      'Draft'
    when Channel::Statuses::PENDING_REVIEW
      'Pending approval'
    when Channel::Statuses::APPROVED
      'Approved'
    when Channel::Statuses::REJECTED
      'Rejected'
    else
      raise "can not interpret #{channel.status}"
    end
  end

  def channel_visibility(channel)
    return 'Unlisted' if channel.archived?

    case channel.status
    when Channel::Statuses::DRAFT, Channel::Statuses::PENDING_REVIEW, Channel::Statuses::REJECTED
      'Unlisted'
    when Channel::Statuses::APPROVED
      channel.listed? ? 'Listed' : 'Unlisted'
    else
      raise "can not interpret #{channel.status}"
    end
  end
end
