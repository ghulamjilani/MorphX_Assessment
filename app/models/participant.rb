# frozen_string_literal: true
class Participant < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::HasVirtualFieldsThroughUserReference
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :user
  has_many :issued_system_credits, dependent: :destroy
  has_many :system_credit_entries, dependent: :destroy

  has_many :session_participations, dependent: :destroy
  has_many :sessions, through: :session_participations

  has_many :livestreamers, dependent: :destroy

  has_many :session_invited_immersive_participantships, dependent: :destroy
  has_many :session_invited_livestream_participantships, dependent: :destroy
  # has_many :invited_to_sessions, through: :session_invited_immersive_participantships, source: :session

  has_many :recording_members, dependent: :destroy
  has_many :recorded_members, dependent: :destroy
  has_many :recorded_member_in_sessions, through: :recorded_members, source: :abstract_session, source_type: 'Session'

  def object_label
    "Participant account of #{user.object_label}"
  end

  def system_credit_balance
    _key = "#{__method__}/#{cache_key}"
    Rails.cache.fetch(_key) do
      already_spent = system_credit_entries.pluck(:amount).sum

      issued_system_credits.status_open.pluck(:amount).sum - already_spent
    end
  end
end
