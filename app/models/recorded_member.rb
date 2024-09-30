# frozen_string_literal: true
class RecordedMember < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :participant, touch: true

  belongs_to :abstract_session, polymorphic: true, touch: true

  validates :abstract_session, presence: true
  validates :participant_id, uniqueness: { scope: :abstract_session }

  after_create do
    abstract_session.room.try(:touch) if abstract_session_type == 'Session'
  end

  def display_name
    Rails.cache.fetch("display_name/#{cache_key}") do
      participant.user.public_display_name
    end
  end

  private

  def user
    participant.try(:user)
  end
end
