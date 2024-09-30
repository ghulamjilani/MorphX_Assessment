# frozen_string_literal: true

module ModelConcerns::LiveDeliveryMethodStateMachine
  extend ActiveSupport::Concern

  included do
    # because state_machine is abandoned and with Rails 4.2 :initial option is simply ignored
    after_initialize :set_initial_status

    def set_initial_status
      self.status ||= :confirmed
    end

    state_machine :status, initial: :confirmed do
      # NOTE: you could be paid OR free participant/co-presenter in this session
      event :await_decision_on_changed_start_at do
        # Start At could be changed several times before user decides
        transition %i[confirmed pending_changed_start_at] => :pending_changed_start_at
      end

      # @param model - instance of one the the following classes SessionParticipation, SessionCoPresentership, Livestreamer
      after_transition on: :await_decision_on_changed_start_at do |model|
        participation_or_co_presentersip = model

        participant_or_co_presenter = model.participant_or_co_presenter

        payment_transaction = participation_or_co_presentersip
                              .abstract_session_model
                              .payment_transactions
                              .success
                              .where(user_id: participant_or_co_presenter.user.id)
                              .where(archived: false)
                              .last

        system_credit_entry = if model.is_a?(SessionCoPresentership)
                                nil
                              else
                                participation_or_co_presentersip
                                  .abstract_session_model
                                  .system_credit_entries
                                  .where(archived: false)
                                  .where(participant_id: model.participant_id)
                                  .last
                              end

        if payment_transaction.present? && system_credit_entry.present?
          raise "#{participation_or_co_presentersip.abstract_session_model.class} should not have 2 payment methods at once - #{participation_or_co_presentersip.inspect}"
        end

        if payment_transaction.present?
          # fixes #998  - Start At could be changed several times before user makes his decision.
          # only the latest one is useable.
          PendingRefund.where(user: participant_or_co_presenter.user,
                              payment_transaction: payment_transaction).map(&:destroy)

          PendingRefund.new(user: participant_or_co_presenter.user, payment_transaction: payment_transaction)
                       .save_and_notify_about_updated_start_at!(participation_or_co_presentersip)
        else
          # it is a free session for that participant_or_co_presenter
          model
            .abstract_session_model
            .notify_about_changed_start_at_without_pending_stripe_refund(participant_or_co_presenter) # could be system credit, or free purchase
        end
      end

      event :decline_changed_start_at do
        transition [:pending_changed_start_at] => :declined_changed_start_at
      end

      # NOTE: you're in this session without getting paid by stripe(completely free, free trial or sys credit purchase)
      after_transition on: :decline_changed_start_at do |participation_or_co_presentersip|
        abstract_session = participation_or_co_presentersip.abstract_session_model

        case participation_or_co_presentersip
        when SessionParticipation, Livestreamer

          participant_id = participation_or_co_presentersip.participant_id
          presenter_id = nil
        when SessionCoPresentership
          participant_id = nil
          presenter_id = participation_or_co_presentersip.presenter_id
        else
          raise "can not interpret #{participation_or_co_presentersip.inspect}"
        end

        if abstract_session.is_a?(Session)

          system_credit_transaction = SystemCreditEntry.where(commercial_document: abstract_session,
                                                              participant_id: participant_id, archived: false).last
          if system_credit_transaction.present?
            system_credit_transaction.system_credit_refund!(system_credit_transaction.amount)

            system_credit_transaction.update({ archived: true }) # so that you can purchase this session again
          end

          abstract_session.session_participations.where(participant_id: participant_id).map(&:destroy)
          abstract_session.session_co_presenterships.where(presenter_id: presenter_id).map(&:destroy)

          abstract_session.livestreamers.where(participant_id: participant_id).map(&:destroy)

          if (obj = abstract_session.session_invited_immersive_participantships.where(participant_id: participant_id).last)
            obj.update_attribute(:status, ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED)
          end

          if (obj = abstract_session.session_invited_livestream_participantships.where(participant_id: participant_id).last)
            obj.update_attribute(:status, ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED)
          end

          if (obj = abstract_session.session_invited_immersive_co_presenterships.where(presenter_id: presenter_id).last)
            obj.update_attribute(:status, ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED)
          end
        else
          raise "can not interpret #{abstract_session.inspect}"
        end

        # TODO: - notify organiser?
      end

      event :accept_changed_start_at do
        transition [:pending_changed_start_at] => :confirmed
      end

      # NOTE: you could be paid OR free participant/co-presenter in this session
      after_transition on: :accept_changed_start_at do |participation_or_co_presentersip|
        participant_or_co_presenter = participation_or_co_presentersip.participant_or_co_presenter
        payment_transaction = participation_or_co_presentersip
                              .abstract_session_model
                              .payment_transactions
                              .success
                              .where(user_id: participant_or_co_presenter.user.id)
                              .last

        if payment_transaction.present?
          PendingRefund.where(user: participant_or_co_presenter.user,
                              payment_transaction: payment_transaction).map(&:destroy)
        end

        # TODO: - notify organizer?
      end
    end
  end
end
