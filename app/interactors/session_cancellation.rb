# frozen_string_literal: true

class SessionCancellation
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::NumberHelper

  def initialize(session, abstract_session_cancel_reason = nil)
    @session                        = session
    @abstract_session_cancel_reason = abstract_session_cancel_reason

    @current_user = session.organizer
  end

  # @return [Boolean]
  def execute
    ActiveRecord::Base.transaction do
      # must be first or mailers would fail
      mark_as_cancelled

      cancel_co_presenters
      cancel_immersive_participants
      cancel_livestream_participants
      cancel_vod_purchases

      cancel_delayed_jobs
      punish_presenter_with_fee unless penalty_amount.zero?

      LiveGuideChannelsAggregator.trigger_live_refresh
      @session.invalidate_nearest_abstract_session_cache_for_everyone_involved
      @session.invalidate_purchased_session_cache_for_everyone_involved
      @session.unchain_all!

      RoomsChannel.broadcast('disable', { room_id: @session.room&.id }) if @session.room

      SidekiqSystem::Schedule.remove(SessionPublishReminder, @session.id)
      SidekiqSystem::Schedule.remove(InvalidateNearestUpcomingAbstractSessionCache, @session.class.to_s, @session.id)
      SidekiqSystem::Schedule.remove(SearchableJobs::UpdatePgSearchDocumentJob, @session.class.to_s, @session.id, { 'after_end_at' => true })
      SearchableJobs::UpdatePgSearchDocumentJob.perform_async(@session.class.name, @session.id)
      true
    end
  end

  def penalty_amount
    types = [TransactionTypes::IMMERSIVE, TransactionTypes::LIVESTREAM]

    co_presenter_user_ids   = @session.session_co_presenterships.collect { |presenter| presenter.user.id }
    paid_participants_count = @session
                              .payment_transactions
                              .success
                              .where(type: types)
                              .where.not(user_id: co_presenter_user_ids) # fixes #1336
                              .count

    if (@session.immersive_delivery_method? || @session.livestream_delivery_method?) && (Time.now < 24.hours.until(@session.start_at) && paid_participants_count < @session.min_number_of_immersive_and_livestream_participants.to_i)
      return 0.0
    end

    penalty_amount_for_paid_immersive_users + penalty_amount_for_paid_livestream_users
  end

  def preview_cancel_modal_message
    immersive_users_count = @session.session_participations.count
    livestream_users_count = @session.livestreamers.count
    total_users_count = immersive_users_count + livestream_users_count

    # FIXME: - not sure whether to include co-presenters here or not
    paid_immersive_participants_count = @session.paid_immersive_session_participations.count

    if penalty_amount.zero?
      I18n.t('sessions.preview_cancel_modal_with_zero_fee',
             cancellation_policy_link: %(<a target="_blank" href="#{Rails.application.class.routes.url_helpers.page_path(ContentPages::REFUND_AND_CANCELLATION_POLICY.parameterize(separator: '-'))}">Cancellation Policy</a>),
             abstract_session_link: %(<a target="_blank" href="#{@session.absolute_path}">#{@session.always_present_title}</a>),
             abstract_channel_link: %(<a target="_blank" href="#{@session.channel.absolute_path}">#{@session.channel.always_present_title}</a>),
             customer_support: mail_to(Rails.application.credentials.global[:support_mail]),
             total_users_count: total_users_count,
             paid_immersive_participants_count: paid_immersive_participants_count,
             paid_livestream_users_count: @session.payment_transactions.success.where(type: TransactionTypes::LIVESTREAM).count)
    else
      I18n.t('sessions.preview_cancel_modal_with_non_zero_fee',
             cancellation_policy_link: %(<a target="_blank" href="#{Rails.application.class.routes.url_helpers.page_path(ContentPages::REFUND_AND_CANCELLATION_POLICY.parameterize(separator: '-'))}">Cancellation Policy</a>),
             abstract_session_link: %(<a target="_blank" href="#{@session.absolute_path}">#{@session.always_present_title}</a>),
             abstract_channel_link: %(<a target="_blank" href="#{@session.channel.absolute_path}">#{@session.channel.always_present_title}</a>),
             customer_support: mail_to(Rails.application.credentials.global[:support_mail]),
             total_users_count: total_users_count,
             paid_immersive_participants_count: paid_immersive_participants_count,
             paid_livestream_users_count: @session.payment_transactions.success.where(type: TransactionTypes::LIVESTREAM).count,
             per_immersive_participant_penalty_fee: number_to_currency(per_immersive_participant_penalty_fee,
                                                                       precision: 2),
             per_livestream_participant_penalty_fee: number_to_currency(per_livestream_participant_penalty_fee,
                                                                        precision: 2),
             penalty_amount: number_to_currency(penalty_amount, precision: 2))
    end
  end

  private

  def penalty_amount_for_paid_immersive_users
    @penalty_amount_for_paid_immersive_users ||= begin
      result = 0
      @session.paid_immersive_session_participations.each do |_session_participation|
        result += per_immersive_participant_penalty_fee
      end
      result
    end
  end

  def penalty_amount_for_paid_livestream_users
    @penalty_amount_for_paid_livestream_users ||= begin
      result = 0
      @session.paid_livestreamers.each do |_livestreamer|
        result += per_livestream_participant_penalty_fee
      end
      result
    end
  end

  def per_immersive_participant_penalty_fee
    penalty = @session.immersive_purchase_price.to_f * 0.1

    if penalty < SystemParameter.min_session_cancellation_fee_per_paid_immersive_participant.to_f
      penalty = SystemParameter.min_session_cancellation_fee_per_paid_immersive_participant.to_f
    elsif penalty > SystemParameter.max_session_cancellation_fee_per_paid_immersive_participant.to_f
      penalty = SystemParameter.max_session_cancellation_fee_per_paid_immersive_participant.to_f
    end

    penalty
  end

  def per_livestream_participant_penalty_fee
    penalty = @session.livestream_purchase_price.to_f * 0.1

    if penalty < SystemParameter.min_session_cancellation_fee_per_paid_livestream_participant.to_f
      penalty = SystemParameter.min_session_cancellation_fee_per_paid_livestream_participant.to_f
    elsif penalty > SystemParameter.max_session_cancellation_fee_per_paid_livestream_participant.to_f
      penalty = SystemParameter.max_session_cancellation_fee_per_paid_livestream_participant.to_f
    end

    penalty
  end

  def punish_presenter_with_fee
    entry = Plutus::Entry.new(
      description: 'Penalty fee for session cancelation',
      commercial_document: @session,
      debits: [
        { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE, amount: penalty_amount }
      ],
      credits: [
        { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: penalty_amount }
      ]
    )
    entry.save!

    @current_user.presenter.presenter_credit_entries.create!(
      amount: penalty_amount,
      description: "Penalty fee for session cancelation - #{@session.always_present_title}"
    )

    types = [TransactionTypes::IMMERSIVE, TransactionTypes::LIVESTREAM]
    display_names = @session.payment_transactions.success.where(type: types).collect do |bt|
      bt.user.public_display_name
    end

    @current_user.log_transactions.create!(type: LogTransaction::Types::SESSION_CANCELLATION_PENALTY,
                                           abstract_session: @session,
                                           data: { display_names: display_names },
                                           amount: - penalty_amount)
  end

  def cancel_co_presenters
    @session.session_co_presenterships.each do |presentership|
      user = presentership.presenter.user

      SessionMailer.session_cancelled(@session.id, user.id).deliver_later

      braintree_transaction = @session.payment_transactions.success.where(user_id: user.id).last
      if braintree_transaction.present?
        # user may have unclaimed pending refund after changed Start At - just delete it
        # new refund is the same amount anyway
        PendingRefund.where(user: user, payment_transaction: braintree_transaction).destroy_all

        PendingRefund.new(user: user,
                          payment_transaction: braintree_transaction).save_and_notify_about_cancelled_abstract_session!
      end
    end
  end

  def cancel_immersive_participants
    @session.session_participations.each do |participation|
      user = participation.participant.user

      SessionMailer.session_cancelled(@session.id, user.id).deliver_later

      braintree_transaction = @session.payment_transactions.success.immersive_access.where(user_id: user.id).last
      system_credit_entry = @session.system_credit_entries.where(participant_id: user.participant_id).last
      if braintree_transaction.present? # otherwise it is completely free or trial free session
        # user may have unclaimed pending refund after changed Start At - just delete it
        # new refund is the same amount anyway
        PendingRefund.where(user: user, payment_transaction: braintree_transaction).destroy_all

        PendingRefund.new(user: user, payment_transaction: braintree_transaction).save_and_notify_about_cancelled_abstract_session!
      elsif system_credit_entry.present?
        system_credit_entry.system_credit_refund!(system_credit_entry.amount)
      end
    end
  end

  def cancel_livestream_participants
    @session.livestreamers.each do |livestreamer|
      user = livestreamer.participant.user

      SessionMailer.session_cancelled(@session.id, user.id).deliver_later

      braintree_transaction = @session.payment_transactions.success.livestream_access.where(user_id: user.id).last
      system_credit_entry = @session.system_credit_entries.where(participant_id: user.participant_id).last
      if braintree_transaction.present? # otherwise it is completely free or trial free session
        # user may have unclaimed pending refund after changed Start At - just delete it
        # new refund is the same amount anyway
        PendingRefund.where(user: user, payment_transaction: braintree_transaction).destroy_all

        PendingRefund.new(user: user,
                          payment_transaction: braintree_transaction).save_and_notify_about_cancelled_abstract_session!
      elsif system_credit_entry.present?
        system_credit_entry.system_credit_refund!(system_credit_entry.amount)
      end
    end
  end

  def cancel_vod_purchases
    @session.recorded_members.each do |recorded_member|
      user = recorded_member.participant.user

      SessionMailer.session_cancelled(@session.id, user.id).deliver_later

      # NOTE: VOD are always non-free - so it's either braintree or sys credit
      braintree_transaction = @session.payment_transactions.success.vod_access.where(user_id: user.id).last
      system_credit_entry = @session.system_credit_entries.where(participant_id: user.participant_id).last

      if braintree_transaction.present?
        # user may have unclaimed pending refund after changed Start At - just delete it
        # new refund is the same amount anyway
        PendingRefund.where(user: user, payment_transaction: braintree_transaction).destroy_all

        PendingRefund.new(user: user,
                          payment_transaction: braintree_transaction).save_and_notify_about_cancelled_abstract_session!
      elsif system_credit_entry.present?
        system_credit_entry.system_credit_refund!(system_credit_entry.amount)
      else
        raise "can not interpret - #{recorded_member.inspect}"
      end
    end
  end

  def mark_as_cancelled
    @session.stop!('cancelled')
    SessionsChannel.broadcast 'session-cancelled', { session_id: @session.id }

    @session.abstract_session_cancel_reason_id = @abstract_session_cancel_reason.id

    @session.cancelled_at = Time.zone.now
    @session.save(validate: false)

    SidekiqSystem::Schedule.remove(SessionAccounting, @session.id)
  end

  def cancel_delayed_jobs
    involved_user_ids = User.distinct.joins(:participant)
                            .joins('LEFT JOIN session_invited_immersive_participantships on participants.id = session_invited_immersive_participantships.participant_id')
                            .joins('LEFT JOIN session_invited_livestream_participantships on participants.id = session_invited_livestream_participantships.participant_id')
                            .where('session_invited_immersive_participantships.session_id = :session_id OR session_invited_livestream_participantships.session_id = :session_id', { session_id: @session.id })
                            .pluck(:id)
    involved_user_ids += Participant.joins(:session_participations)
                                    .where(session_participations: { session_id: @session.id })
                                    .pluck(:user_id)
    involved_user_ids << @current_user.id
    involved_user_ids.uniq.each do |user_id|
      SidekiqSystem::Schedule.remove(SessionStartReminder, @session.id, user_id, EmailOnlyFormatPolicy.to_s)
      SidekiqSystem::Schedule.remove(SessionStartReminder, @session.id, user_id, WebOnlyFormatPolicy.to_s)
      SidekiqSystem::Schedule.remove(SessionStartReminder, @session.id, user_id, SmsOnlyFormatPolicy.to_s)
    end
  end
end
