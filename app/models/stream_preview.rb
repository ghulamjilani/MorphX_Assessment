# frozen_string_literal: true
class StreamPreview < ActiveRecord::Base
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :user
  belongs_to :organization
  belongs_to :ffmpegservice_account

  has_many :transcoder_uptimes, as: :streamable, dependent: :destroy

  validates :organization_id,  presence: true
  validates :ffmpegservice_account_id, presence: true, inclusion: { in: lambda { |stream_preview|
                                                                  FfmpegserviceAccount.where("organization_id = :id OR (reserved_by_type = 'Organization' AND reserved_by_id = :id)", { id: stream_preview.organization_id }).pluck(:id)
                                                                } }

  scope :passed, -> { where("created_at > (now() - (INTERVAL '5 minutes')) OR stopped_at IS NOT NULL") }
  scope :ongoing, -> { where("now() < (created_at + (INTERVAL '5 minutes'))") }
  scope :not_stopped, -> { where(stopped_at: nil) }
  scope :stopped, -> { where.not(stopped_at: nil) }
  scope :not_finished, -> { where("now() < (created_at + (INTERVAL '5 minutes')) AND stopped_at IS NULL") }

  def end_at
    created_at + 5.minutes
  end

  def stopped?
    stopped_at.present?
  end

  def ended?
    stopped? || Time.now > end_at
  end

  def stop!
    ffmpegservice_account.stream_off!
    update_attribute(:stopped_at, Time.now) unless stopped?
  end
end
