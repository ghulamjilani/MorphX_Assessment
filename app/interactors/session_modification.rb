# frozen_string_literal: true

class SessionModification
  include SessionCreationModificationBehavior

  def initialize(session:,
                 clicked_button_type:,
                 ability:,
                 invited_users_attributes:,
                 list_ids:)

    @session = session
    @clicked_button_type = clicked_button_type
    @ability = ability
    @invited_users_attributes = invited_users_attributes
    @list_ids = list_ids.to_a

    emails1 = @invited_users_attributes.select { |h| h[:add_as_contact] }.pluck(:email)
    @add_as_contacts_emails = emails1

    @organizer_pays_for_co_presenter_emails = @invited_users_attributes.select do |h|
      h[:organizer_pays]
    end.pluck(:email)

    @current_user = session.organizer || session.channel.organizer
    @existing_invited_immersive_participant_emails  = []
    @existing_invited_liveast_participant_emails    = []

    @existing_invited_immersive_co_presenter_emails = []
  end

  def if_save_true(result)

  end

  # @return [Boolean]
  def execute
    @session.start_at = 10.seconds.from_now if @session.start_now

    if !@session.channel.listed? || !@session.channel.autoshow_sessions_on_home ||
       @session.channel.archived? || @session.channel.fake
      @session.show_on_home = false
    end
    @session.fake = @session.channel.fake

    if @session.immersive_delivery_method?
      if @session.max_number_of_immersive_participants == 1
        @session.immersive_type = 'one_on_one'
      elsif @session.max_number_of_immersive_participants > 1
        @session.immersive_type = 'group'
      end
    end
    validate_clicked_button_type!
    check_protected_fields_were_not_affected

    # changes = @session.changes
    # NOTE: #validate_enough_invited_participants_if_private has to go after #valid? because otherwise those custom errors would be lost(added outside model itself)
    assign_pay_promises && validate_enough_invited_participants_if_private && @session.save.tap do |result|
      if result
        # after_save_status_modification(@session, changes)

        SessionJobs::EditInvitedUsersJob.perform_async(@session.id, @current_user.id, @invited_users_attributes)

        @session.organizer.touch

        UserJobs::AddContactUsersJob.perform_async(@current_user.id, @add_as_contacts_emails)
        CreateTwitterWidget.perform(@session.id) if @session.twitter_feed_title.present? && @session.twitter_feed_widget_id.blank?

        if @list_ids
          # reject not owned lists
          owned_list_ids = @current_user.current_organization.list_ids

          @list_ids.delete_if { |id| owned_list_ids.exclude?(id.to_i) }
          @session.list_ids = @list_ids
        end

        begin
          CreateRecurringSession.perform(session: @session)
        rescue StandardError => e
          @session.errors.add(:base, e.message)
          return false
        end

        true
      else
        result
      end
    end
  end

  def charge_amount
    (@organizer_pays_for_co_presenter_emails - already_promised_to_pay_for_co_presenter_emails).length * SystemParameter.co_presenter_fee.to_f
  end

  def already_promised_to_pay_for_co_presenter_emails
    @already_promised_to_pay_for_co_presenter_emails ||= @session.organizer_abstract_session_pay_promises.collect do |promise|
      promise.co_presenter.email
    end
  end

  attr_reader :session

  private

  def assign_pay_promises
    @session.organizer_abstract_session_pay_promises.select do |promise|
      # NOTE: disabled input fields are not sent as HTML protocol describes, so @organizer_pays_for_co_presenter_emails could be blank in this case
      # that's why we have that workaround
      not_accepted = @session.invited_co_presenter_status(promise.co_presenter) != ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED

      # NOTE: - once invitation is accepted by co-presenter - organizer can no longed uncheck pay promise
      not_accepted && @organizer_pays_for_co_presenter_emails.exclude?(promise.co_presenter.email)
    end.each(&:mark_for_destruction)

    (@organizer_pays_for_co_presenter_emails - already_promised_to_pay_for_co_presenter_emails).each do |email|
      user = User.find_by(email: email.to_s.downcase)
      user.create_presenter! if user.presenter.blank?

      @session.organizer_abstract_session_pay_promises.build(co_presenter: user.presenter, abstract_session: @session)
    end
    true
  end

  def check_protected_fields_were_not_affected
    @session.update_by_organizer = true

    if @session.immersive_purchase_price_changed? && !@session.can_change_immersive_purchase_price?
      @session.immersive_purchase_price = @session.immersive_purchase_price_was
    end

    if @session.livestream_purchase_price_changed? && !@session.can_change_livestream_purchase_price?
      @session.livestream_purchase_price = @session.livestream_purchase_price_was
    end

    if @session.recorded_purchase_price_changed? && !@session.can_change_recorded_purchase_price?
      @session.recorded_purchase_price = @session.recorded_purchase_price_was
    end

    if @session.immersive_free_slots_changed? && !@session.can_change_immersive_free_slots?
      @session.immersive_free_slots = @session.immersive_free_slots_was
    end

    if @session.livestream_free_slots_changed? && !@session.can_change_livestream_free_slots?
      @session.livestream_free_slots = @session.livestream_free_slots_was
    end

    if @session.can_change_start_at? && @session.start_at_changed?
      @session.former_start_at = @session.start_at_was
    end

    if !@session.can_change_start_at? && @session.start_at_changed?
      @session.start_at = @session.start_at_was
    end

    if !@session.can_change_duration? && @session.duration_changed?
      @session.duration = @session.duration_was
    end

    if !@session.can_change_immersive_type? && @session.immersive_type_changed?
      @session.immersive_type = @session.immersive_type_was
    end

    if !@session.can_change_pre_time? && @session.pre_time_changed?
      @session.pre_time = @session.pre_time_was
    end

    if !@session.can_change_min_number_of_immersive_and_livestream_participants? && @session.min_number_of_immersive_and_livestream_participants_changed?
      @session.min_number_of_immersive_and_livestream_participants = @session.min_number_of_immersive_and_livestream_participants_was
    end

    if !@session.can_change_max_number_of_immersive_participants? && @session.max_number_of_immersive_participants_changed?
      @session.max_number_of_immersive_participants = @session.max_number_of_immersive_participants_was
    end
  end
end
