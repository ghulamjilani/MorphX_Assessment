# frozen_string_literal: true

class SessionMailerPreview < ApplicationMailerPreview
  def free_private_session_was_approved_automatically
    ::SessionMailer.free_session_was_approved_automatically(Session.where(private: true).order(Arel.sql('random()')).pick(:id),
                                                            FreeSessionPublishedAutomaticallyReasons::APPROVED_PRIVATE_AUTOMATICALLY_BECAUSE_OF_PREFERENCE)
  rescue StandardError => e
    fallback_mail(e)
  end

  def free_session_was_approved_automatically_because_of_limit
    ::SessionMailer.free_session_was_approved_automatically(Session.where(private: false).order(Arel.sql('random()')).pick(:id),
                                                            FreeSessionPublishedAutomaticallyReasons::APPROVED_BECAUSE_OF_LIMIT)
  rescue StandardError => e
    fallback_mail(e)
  end

  def pending_requested_free_session_appeared
    ::SessionMailer.pending_requested_free_session_appeared(Session.order(Arel.sql('random()')).pick(:id))
  rescue StandardError => e
    fallback_mail(e)
  end

  def published_session_from_user_you_follow
    ::SessionMailer.published_session_from_user_you_follow(Session.order(Arel.sql('random()')).pick(:id), User.order(Arel.sql('random()')).pick(:id))
  rescue StandardError => e
    fallback_mail(e)
  end

  def published_session_from_channel_you_follow
    ::SessionMailer.published_session_from_channel_you_follow(Session.order(Arel.sql('random()')).pick(:id), User.order(Arel.sql('random()')).pick(:id))
  rescue StandardError => e
    fallback_mail(e)
  end

  def session_cancelled
    session = Session.cancelled.sample or raise 'can not find session'

    ::SessionMailer.session_cancelled(session.id, User.order(Arel.sql('random()')).pick(:id))
  rescue StandardError => e
    fallback_mail(e)
  end

  def you_obtained_recorded_access
    # veryfing both eventually
    transaction_id = [true, false].sample ? PaymentTransaction.order(Arel.sql('random()')).pick(:id) : nil

    ::SessionMailer.you_obtained_recorded_access(Session.order(Arel.sql('random()')).pick(:id), User.order(Arel.sql('random()')).pick(:id), transaction_id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def requested_free_session_submitted_for_review
    ::SessionMailer.requested_free_session_submitted_for_review(Session.order(Arel.sql('random()')).pick(:id))
  rescue StandardError => e
    fallback_mail(e)
  end

  def requested_free_session_just_got_granted
    free_session = ::Session.where(status: Session::Statuses::REQUESTED_FREE_SESSION_APPROVED).sample
    # if no session found
    unless free_session
      # Check pending session
      free_session = ::Session.where(status: Session::Statuses::REQUESTED_FREE_SESSION_PENDING).sample
      # Or create new one
      free_session ||= FactoryBot.create(:pending_completely_free_session)
      # and approve it
      free_session.status = ::Session::Statuses::REQUESTED_FREE_SESSION_APPROVED
      free_session.save!
    end
    ::SessionMailer.requested_free_session_just_got_granted(free_session.id)
  end

  def requested_free_session_just_got_rejected
    session = Session.where(status: Session::Statuses::REQUESTED_FREE_SESSION_REJECTED).sample

    if session.blank?
      session = ::FactoryBot.create(:immersive_session, channel: Channel.all.sample)
      session.requested_free_session_declined_with_message = 'because we are not interested'
      session.status = ::Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
      session.save(validate: false)
    end

    ::SessionMailer.requested_free_session_just_got_rejected(session.id)
  end

  def session_publish_reminder
    model_id = Session.order(Arel.sql('random()')).pick(:id)

    ::SessionMailer.publish_reminder(model_id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def you_as_co_presenter_accepted_session_invitation
    SessionMailer.you_as_co_presenter_accepted_session_invitation(Session.order(Arel.sql('random()')).pick(:id), Participant.order(Arel.sql('random()')).pick(:user_id))
  rescue StandardError => e
    fallback_mail(e)
  end

  def co_presenter_invited_to_session
    ::SessionMailer.co_presenter_invited_to_session Session.order(Arel.sql('random()')).pick(:id), Presenter.order(Arel.sql('random()')).pick(:id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def co_presenter_rejected_from_session
    ::SessionMailer.co_presenter_rejected_from_session Session.order(Arel.sql('random()')).pick(:id), Presenter.order(Arel.sql('random()')).pick(:id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def participant_rejected_from_session
    ::SessionMailer.participant_rejected_from_session Session.order(Arel.sql('random()')).pick(:id), Participant.order(Arel.sql('random()')).pick(:id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def presenter_assigned_to_session
    ::SessionMailer.presenter_assigned_to_session Session.order(Arel.sql('random()')).pick(:id), Presenter.order(Arel.sql('random()')).pick(:id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def presenter_unassigned_from_session
    ::SessionMailer.presenter_unassigned_from_session Session.order(Arel.sql('random()')).pick(:id), Presenter.order(Arel.sql('random()')).pick(:id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def free_abstract_session_notify_about_changed_start_at_for_participants_of_session
    sp = SessionParticipation.joins(:session).where.not(sessions: { former_start_at: nil }).sample
    unless sp
      s = Session.where.not(sessions: { former_start_at: nil }).sample
      s ||= ::FactoryBot.create(:immersive_session, start_at: 1.hour.from_now, former_start_at: 2.hours.from_now)
      sp = ::FactoryBot.create(:session_participation, session: s)
    end
    SessionMailer.free_abstract_session_notify_about_changed_start_at(sp.session.id, sp.participant)
  end

  def free_abstract_session_notify_about_changed_start_at_for_livestreamer
    l = Livestreamer.joins(:session).where.not(sessions: { former_start_at: nil }).sample
    SessionMailer.free_abstract_session_notify_about_changed_start_at(l.session.id, l.participant)
  end

  def free_abstract_session_notify_about_changed_start_at_for_co_presenters
    sc = SessionCoPresentership.joins(:session).where.not(sessions: { former_start_at: nil }).sample
    SessionMailer.free_abstract_session_notify_about_changed_start_at(sc.session.id, sc.presenter)
  end

  def waiting_list_hurry_up_to_purchase_line_slot
    SessionMailer.hurry_up_to_purchase_slot Session.order(Arel.sql('random()')).pick(:id), User.order(Arel.sql('random()')).pick(:id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def you_obtained_access_to_session_immersive_free
    stripe_transaction_id = nil
    system_credit_entry_id   = nil
    sp                       = SessionParticipation.all.sample

    SessionMailer.you_obtained_live_access(sp.session.id, sp.participant.user.id, stripe_transaction_id,
                                           system_credit_entry_id)
  end

  def you_obtained_access_to_session_immersive_non_free
    transaction_id = PaymentTransaction.immersive_access.order(Arel.sql('random()')).pick(:id) or raise 'can not find'
    system_credit_entry_id   = nil
    sp                       = SessionParticipation.all.sample

    SessionMailer.you_obtained_live_access(sp.session.id, sp.participant.user.id, transaction_id,
                                           system_credit_entry_id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def you_obtained_access_to_session_livestream_free
    stripe_transaction_id = nil
    system_credit_entry_id   = nil

    sw                       = Livestreamer.all.sample or raise 'can not find'

    SessionMailer.you_obtained_live_access(sw.session.id, sw.participant.user.id, stripe_transaction_id,
                                           system_credit_entry_id)
  end

  def you_obtained_access_to_session_livestream_non_free
    transaction_id = PaymentTransaction.livestream_access.order(Arel.sql('random()')).pick(:id) or raise 'can not find payment transaction sample for livestream access'
    system_credit_entry_id   = nil
    sw                       = Livestreamer.all.sample

    SessionMailer.you_obtained_live_access(sw.session.id, sw.participant.user.id, transaction_id,
                                           system_credit_entry_id)
  rescue StandardError => e
    fallback_mail(e)
  end
end
