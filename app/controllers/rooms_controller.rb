# frozen_string_literal: true

class RoomsController < ApplicationController
  before_action :authenticate_user!

  # TODO: delete?
  def toggle_notify_me
    room = Room.find(params[:id])

    @abstract_session = room.abstract_session

    membership = PendingVodAvailabilityMembership.where(abstract_session: @abstract_session, user: current_user).first

    if membership.present?
      membership.destroy
      @result = false
    else
      PendingVodAvailabilityMembership.create!(abstract_session: @abstract_session, user: current_user)
      @result = true
    end

    # HACK: to test it from Capybara :(
    render "rooms/#{__method__}"
  end

  def show
    @room = Room.includes(:abstract_session).with_open_lobby.not_cancelled.find(params[:id])
    @abstract_session = @room.abstract_session
    if @room.abstract_session.is_a?(Session) && !@room.abstract_session.published?
      raise ActiveRecord::RecordNotFound, 'Session is not published or not approved'
    end

    @role = @room.role_for(user: current_user)
    raise ActiveRecord::RecordNotFound, "Couldn't find Session without an ID" unless @role

    member = RoomMember.find_or_initialize_by(abstract_user: current_user, kind: @role, room: @room)
    # member.joined = true
    member.save!
  end
end
