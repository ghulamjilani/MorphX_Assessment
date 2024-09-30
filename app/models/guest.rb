# frozen_string_literal: true
class Guest < ApplicationRecord
  include ModelConcerns::Shared::HasSecret

  has_many :conversation_participants, class_name: '::Im::ConversationParticipant', as: :abstract_user, dependent: :destroy
  has_many :conversations, class_name: '::Im::Conversation', through: :conversation_participants
  has_many :room_members, as: :abstract_user, dependent: :destroy

  validates :public_display_name, presence: true

  def jwt_secret
    Digest::MD5.hexdigest(secret + Rails.application.secret_key_base)
  end

  def avatar_url
    @avatar_url ||= User.new.avatar_url
  end

  def slug
  end

  def relative_path
  end
end
