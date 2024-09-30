# frozen_string_literal: true

class SessionCreation
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

    @payment_transactions = []
    @current_user = session.organizer || session.channel.organizer
  end

  # @return [Boolean]
  def execute
    raise 'must be not persisted, that is session creation' if @session.persisted?

    @session.start_at = 2.seconds.from_now if @session.start_now

    if !@session.channel.listed? || !@session.channel.autoshow_sessions_on_home ||
       @session.channel.archived? || @session.channel.fake
      @session.show_on_home = false
    end
    @session.fake = @session.channel.fake

    if @session.immersive_delivery_method?
      if @session.max_number_of_immersive_participants.to_i == 1
        @session.immersive_type = 'one_on_one'
      elsif @session.max_number_of_immersive_participants.to_i > 1
        @session.immersive_type = 'group'
      end
    end

    validate_clicked_button_type!

    # NOTE: #validate_enough_invited_participants_if_private has to go after #valid? because otherwise those custom errors would be lost(added outside model itself)
    assign_pay_promises && @session.valid? && validate_enough_invited_participants_if_private && @session.save.tap do |result|
      if result
        # after_save_status_modification(@session)
        SessionJobs::AssignInvitedUsersJob.perform_async(@session.id, @current_user.id, @invited_users_attributes)
        # FIXME: for some reason something blocks normal carrierwave's processing of images. This line can be removed
        # if original issue is fixed.
        @session.cover.recreate_versions! if @session.cover.present?
        LiveGuideChannelsAggregator.trigger_live_refresh
        @session.organizer.touch
        UserJobs::AddContactUsersJob.perform_async(@current_user.id, @add_as_contacts_emails)

        CreateTwitterWidget.perform(@session.id) if @session.twitter_feed_title.present?

        if @list_ids.present?
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

  attr_reader :session

  private

  def assign_pay_promises
    @invited_users_attributes.select { |h| h[:organizer_pays] }.pluck(:email).each do |email|
      user = User.find_by(email: email.to_s.downcase)
      user.create_presenter! if user.presenter.blank?

      @session.organizer_abstract_session_pay_promises.build(co_presenter: user.presenter, abstract_session: @session)
    end
    true
  end

  def assign_invited_users
    @invited_users_attributes.each do |hash|
      email = hash[:email] or raise
      raise unless ModelConcerns::Session::HasInvitedUsers::States::ALL.include?(hash[:state])

      if (user = User.find_by(email: email.to_s.downcase))
        user.create_participant! if user.participant.blank?

        if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM ||
           hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE
          @session.session_invited_immersive_participantships.build(participant: user.participant, session: @session)
        end

        if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM ||
           hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
          @session.session_invited_livestream_participantships.build(participant: user.participant, session: @session)
        end

        if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER
          user.create_presenter! if user.presenter.blank?
          @session.session_invited_immersive_co_presenterships.build(presenter: user.presenter, session: @session)
        end
      else
        user = User.invite!({ email: email }, @current_user) do |u|
          u.before_create_generic_callbacks_and_skip_validation
          u.skip_invitation = true
        end

        if user.valid?
          user.create_presenter! if user.presenter.blank?
          user.create_participant! if user.participant.blank?

          if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE
            @session.session_invited_immersive_participantships.build(participant: user.participant, session: @session)
          end

          if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
            @session.session_invited_livestream_participantships.build(participant: user.participant, session: @session)
          end

          if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER
            @session.session_invited_immersive_co_presenterships.build(presenter: user.presenter, session: @session)
          end
        else
          if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE
            @session.session_invited_immersive_participantships.build(
              participant: Participant.new(user: User.new(email: email)), session: @session
            )
          end

          if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM || hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM
            @session.session_invited_livestream_participantships.build(
              participant: Participant.new(user: User.new(email: email)), session: @session
            )
          end

          if hash[:state] == ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER
            @session.session_invited_immersive_co_presenterships.build(
              presenter: Presenter.new(user: User.new(email: email)), session: @session
            )
          end
        end
      end
    end
    true
  end
end
