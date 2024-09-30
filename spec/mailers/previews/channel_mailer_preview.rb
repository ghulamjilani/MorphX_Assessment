# frozen_string_literal: true

class ChannelMailerPreview < ApplicationMailerPreview
  def presenter_invited
    ::ChannelMailer.presenter_invited Channel.order(Arel.sql('random()')).pick(:id), Presenter.order(Arel.sql('random()')).pick(:id)
  end

  def presenter_rejected
    ::ChannelMailer.presenter_rejected Channel.order(Arel.sql('random()')).pick(:id), Presenter.order(Arel.sql('random()')).pick(:id)
  end

  def presenter_accepted_your_invitation
    ::ChannelMailer.presenter_accepted_your_invitation(Channel.order(Arel.sql('random()')).pick(:id), Presenter.order(Arel.sql('random()')).pick(:id))
  end

  def presenter_rejected_your_invitation
    ::ChannelMailer.presenter_rejected_your_invitation(Channel.order(Arel.sql('random()')).pick(:id), Presenter.order(Arel.sql('random()')).pick(:id))
  end

  def notify_about_1st_published_session
    session = Session.upcoming.published.first!

    ::ChannelMailer.notify_about_1st_published_session(session.channel_id, User.order(Arel.sql('random()')).pick(:id))
  rescue StandardError => e
    fallback_mail(e)
  end

  def draft_channel_reminder
    ::ChannelMailer.draft_channel_reminder(Channel.order(Arel.sql('random()')).pick(:id))
  end

  def pending_channel_appeared
    ::ChannelMailer.pending_channel_appeared(Channel.order(Arel.sql('random()')).pick(:id))
  end

  def channel_rejected
    ::ChannelMailer.channel_rejected(Channel.rejected.order(Arel.sql('random()')).pick(:id))
  end

  def channel_approved
    ::ChannelMailer.channel_approved(Channel.order(Arel.sql('random()')).pick(:id))
  end

  def channel_updated
    channel = Channel.order(Arel.sql('random()')).first
    values_before = { title: %w[OldTitle NewTitle], description: ['OldDescription', 'New description'] }
    ::ChannelMailer.channel_updated values_before, channel, 'admin1@example.com'
  end
end
