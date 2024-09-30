# frozen_string_literal: true

class Api::V1::User::SessionInvitedLivestreamParticipantshipsController < Api::V1::User::ApplicationController
  before_action :set_session, only: %i[index create]
  before_action :set_participantship, only: %i[show update destroy]

  def index
    query = if @session.present?
              if current_ability.can?(:invite_to_session, @session)
                @session.session_invited_livestream_participantships
              else
                @session.session_invited_livestream_participantships.where(participant_id: current_user.participant&.id)
              end
            else
              current_user.participant.session_invited_livestream_participantships
            end

    query = query.where(status: params[:status]) if params[:status].present?

    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
    @participantships = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
    @count = @participantships.count
  end

  def show
  end

  def create
    return render_json(403, { message: message }) unless current_ability.can?(:invite_to_session, @session)

    user = if params[:email].present?
             ::User.find_or_invite_by_email(params[:email], current_user)
           elsif params[:user_id].present?
             ::User.find_by(id: params[:user_id])
           end

    return render_json(422, 'email or user_id is invalid.') if user.blank?

    user.create_participant! if user.participant.blank?

    @participantship = @session.session_invited_livestream_participantships.create!(participant: user.participant)

    @session.notify_unnotified_invited_participants

    render :show
  end

  def update
    unless current_ability.can?(:change_status_as_participant, @participantship)
      return render_json(403, { message: 'You are not allowed to perform this action.' })
    end

    unless [
      ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED,
      ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED
    ].include?(params[:status])
      return render_json(422, { message: "This status is not allowed: '#{params[:status]}'" })
    end

    if current_ability.cannot?(:accept_or_reject_invitation, @session)
      message = if @session.finished?
                  'The session you are trying to access has ended'
                elsif @session.cancelled?
                  'The session you are trying to access has been cancelled'
                elsif @session.stopped?
                  'The session you are trying to access has been stopped'
                elsif !@session.published?
                  'The session you are trying to access is not published'
                else
                  'You are not allowed to perform this action.'
                end
      return render_json(403, { message: message })
    end

    if params[:status] == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED
      return render_json(403, { message: 'You cannot reject this invitation.' }) if current_ability.cannot?(
        :reject_invitation, @participantship
      )

      @participantship.reject!
      return render :show
    end

    if current_ability.can?(:accept_invitation_without_paying, @participantship)
      @participantship.accept!
      @session.session_participations.create!(participant: current_user.participant)
      return render :show
    elsif current_ability.can?(:purchase_livestream_access, @session) && @participantship.pending?
      return render_json(403,
                         { message: 'The session is paid',
                           redirect_url: preview_purchase_channel_session_path(@session.slug,
                                                                               type: ObtainTypes::PAID_IMMERSIVE) })
    end

    return render_json(403, { message: 'You are not allowed to perform this action.' }) if current_ability.cannot?(
      :accept_invitation, @participantship
    )

    render :show
  end

  def destroy
    if @participantship.status == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED
      return render_json(422, { message: 'User has already accepted this invitation.' })
    end

    unless current_ability.can?(:destroy_invitation, @participantship)
      return render_json(403, { message: 'You are not allowed to perform this action.' })
    end

    @participantship.destroy!
    render :show
  end

  private

  def set_session
    if params[:session_id].present?
      @session = Session.find(params[:session_id])
      @room = @session.room
    elsif params[:room_id].present?
      @room = Room.find(params[:room_id])
      @session = @room.abstract_session
    end
  end

  def set_participantship
    @participantship = SessionInvitedLivestreamParticipantship.find(params[:id])
    unless current_ability.can?(:invite_to_session,
                                @participantship.session) || @participantship.participant_id == current_user.participant&.id
      return render_json(403, { message: 'You are not allowed to perform this action.' })
    end

    @session = @participantship.session
  end
end
