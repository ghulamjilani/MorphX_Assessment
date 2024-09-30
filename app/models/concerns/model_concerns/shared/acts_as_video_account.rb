# frozen_string_literal: true

module ModelConcerns::Shared::ActsAsVideoAccount
  extend ActiveSupport::Concern

  included do
    has_one :room, as: :abstract_session, dependent: :destroy, autosave: true

    before_validation :assign_room
    after_commit -> { room&.reload&.destroy if cancelled_at? }, on: :update
  end

  def assign_room
    unless cancelled_at?
      ::Room.assign_room(self)
    end
  end
end
