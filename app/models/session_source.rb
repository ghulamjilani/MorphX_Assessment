# frozen_string_literal: true
class SessionSource < ActiveRecord::Base
  belongs_to :session

  validates :name, presence: true

  after_create :create_room_member
  after_destroy :delete_room_member

  def user
    session.organizer
  end

  def create_room_member
    RoomMember.find_or_create_by(abstract_user: user, kind: RoomMember::Kinds::SOURCE, room: session.room)
  end

  def delete_room_member
    RoomMember.find_by(abstract_user: user, kind: RoomMember::Kinds::SOURCE, room: session.room).try(:delete)
  end
end
