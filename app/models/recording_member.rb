# frozen_string_literal: true
class RecordingMember < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :participant, touch: true
  belongs_to :recording, touch: true

  validates :participant_id, uniqueness: { scope: :recording }

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
