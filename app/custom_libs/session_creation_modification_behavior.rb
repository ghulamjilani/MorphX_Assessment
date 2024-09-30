# frozen_string_literal: true

module SessionCreationModificationBehavior
  # NOTE: this method is used like:
  #  set_updated_invited_co_presenters \
  #    && set_updated_invited_participants \
  #    && assign_pay_promises \
  #    && @session.valid? \
  #    && validate_enough_invited_participants_if_private \
  #    && @session.save.tap { |result|
  #
  # @return [Boolean]
  def validate_enough_invited_participants_if_private
    # IMD-275
    # if @session.private? && @clicked_button_type == SessionFormButtonTypes::SAVE_AS_NON_DRAFT
    #   unique_invited_participants_count = (@session.session_invited_immersive_participantships + @session.session_invited_livestream_participantships).collect(&:participant_id).uniq.length
    #   if @session.min_number_of_immersive_and_livestream_participants > unique_invited_participants_count
    #     @session.errors.add(:base, 'Can not publish a private session, unless min number of participants are invited.')
    #   end
    # end
    @session.errors.blank?
  end

  def validate_clicked_button_type!
    unless SessionFormButtonTypes::ALL.include?(@clicked_button_type)
      raise " can not interpret @clicked_button_type - #{@clicked_button_type}"
    end
  end

  # NOTE: the reason changes are passed separately is because it is saved before update
  # and after_save_status_modification is called after(so changes are blank at that moment)
  def after_save_status_modification(_session, changes = {})
    return if @session.published? && !non_free_session_just_switched_to_free_session?(changes)

    if !@session.private?
      @session.update!(status: ::Session::Statuses::PUBLISHED) if !@session.published? && @ability.can?(:publish, @session.reload)
    elsif non_free_session_just_switched_to_free_session?(changes) # if @session.immersive_free || @session.livestream_free
      non_free_session_just_switched_to_free_session_save_update
    else
      regular_after_save_update
      # else
      #   raise '#requested_free_session has to be set'
    end

    LiveGuideChannelsAggregator.trigger_live_refresh
  end

  private

  def non_free_session_just_switched_to_free_session?(changes)
    changes.key?('immersive_free') || changes.key?('livestream_free')
  end

  def non_free_session_just_switched_to_free_session_save_update
    case @clicked_button_type
    when SessionFormButtonTypes::SAVE_AS_NON_DRAFT
      # IMD-276
      evaluate_can_publish_n_free_sessions_without_admin_approval = lambda do
        if @session.organizer&.presenter && !@session.organizer.can_publish_n_free_sessions_without_admin_approval.zero?
          channel_ids = @session.organizer.presenter.channels.pluck(:id)

          free_count = Session.where(id: channel_ids).where('immersive_purchase_price = 0 OR livestream_purchase_price = 0').count
          free_count < @session.organizer.can_publish_n_free_sessions_without_admin_approval
        else
          false
        end
      end

      if !@session.private? || (@session.private? && (@session.organizer.can_create_free_private_sessions_without_permission? || @session.organizer.free_private_sessions_without_admin_approval_left_count.positive?))
        @session.status = Session::Statuses::PUBLISHED
        @session.save!

        SessionMailer
          .free_session_was_approved_automatically(@session.id, FreeSessionPublishedAutomaticallyReasons::APPROVED_PRIVATE_AUTOMATICALLY_BECAUSE_OF_PREFERENCE)
          .deliver_later
      elsif evaluate_can_publish_n_free_sessions_without_admin_approval.call
        @session.status = Session::Statuses::PUBLISHED
        @session.save!

        SessionMailer
          .free_session_was_approved_automatically(@session.id, FreeSessionPublishedAutomaticallyReasons::APPROVED_BECAUSE_OF_LIMIT)
          .deliver_later
      else
        @session.status = ::Session::Statuses::REQUESTED_FREE_SESSION_PENDING
        @session.save!

        SessionMailer.requested_free_session_submitted_for_review(@session.id).deliver_later
      end
    when SessionFormButtonTypes::SAVE_AS_DRAFT
      @session.status = ::Session::Statuses::UNPUBLISHED
      @session.save!
    else
      raise "unknown @clicked_button_type - #{@clicked_button_type}"
    end
  end

  def regular_after_save_update
    case @clicked_button_type
    when SessionFormButtonTypes::SAVE_AS_NON_DRAFT
      evaluate_can_publish_n_free_sessions_without_admin_approval = lambda do
        if @clicked_button_type == SessionFormButtonTypes::SAVE_AS_NON_DRAFT && @session.organizer &&
           @session.organizer.presenter && !@session.organizer.can_publish_n_free_sessions_without_admin_approval.zero?
          channel_ids = @session.organization.channels.pluck(:id)

          Session.where(channel_id: channel_ids)
                 .where('immersive_purchase_price = 0 OR livestream_purchase_price = 0')
                 .count < @session.organizer.can_publish_n_free_sessions_without_admin_approval
        else
          false
        end
      end

      if !@session.published? && (!@session.private? ||
        (@session.private? && (@session.immersive_free || @session.livestream_free) && (@session.organizer.can_create_free_private_sessions_without_permission? ||
          @session.organizer.free_private_sessions_without_admin_approval_left_count.positive?)))
        @session.status = Session::Statuses::PUBLISHED
        @session.save!

        SessionMailer
          .free_session_was_approved_automatically(@session.id, FreeSessionPublishedAutomaticallyReasons::APPROVED_PRIVATE_AUTOMATICALLY_BECAUSE_OF_PREFERENCE)
          .deliver_later
      elsif evaluate_can_publish_n_free_sessions_without_admin_approval.call
        @session.status = Session::Statuses::PUBLISHED
        @session.save!

        SessionMailer
          .free_session_was_approved_automatically(@session.id, FreeSessionPublishedAutomaticallyReasons::APPROVED_BECAUSE_OF_LIMIT)
          .deliver_later
      elsif @session.status != ::Session::Statuses::REQUESTED_FREE_SESSION_PENDING
        @session.status = ::Session::Statuses::REQUESTED_FREE_SESSION_PENDING
        @session.save!

        SessionMailer.requested_free_session_submitted_for_review(@session.id).deliver_later
      end
    when SessionFormButtonTypes::SAVE_AS_DRAFT
      # Do nothing.
    else
      raise "unknown @clicked_button_type - #{@clicked_button_type}"
    end
  end
end
