# frozen_string_literal: true
class TranscodeTask < ApplicationRecord
  enum status: {
    queued: 0,
    downloading: 1,
    encoding: 2,
    saving: 3,
    completed: 4
  }

  belongs_to :transcodable, polymorphic: true, optional: false

  after_commit :update_transcodable_status, if: :saved_change_to_status?
  after_commit :notify_transcode_progress, if: :saved_change_to_percent?

  scope :for_videos, -> { where(transcodable_type: 'Video') }
  scope :for_recordings, -> { where(transcodable_type: 'Recording') }

  scope :completed, -> { where(status: :completed) }
  scope :not_completed, -> { where.not(status: :completed) }

  def completed?
    status == 'completed'
  end

  def completed!
    update(status: :completed)
  end

  def task_params
    JSON.parse(params).with_indifferent_access
  end

  private

  def update_transcodable_status
    return unless completed? && transcodable.status.to_sym.eql?(:transcoding)

    notify_transcode_completed

    if error.to_i.zero?
      transcodable.update(status: :transcoded, error_reason: nil)
      if transcodable.is_a?(Video) && transcodable.room.present?
        transcodable.room.update_column(:vod_is_fully_ready, true)
      end
      return
    end

    if transcodable.error_reason.nil?
      transcodable.update(status: :ready_to_tr, error_reason: 'transcode_error1')
      return
    end

    transcodable.update(status: :error, error_reason: 'transcode_error2')
  end

  def notify_transcode_progress
    return if transcodable.channel.blank?

    ChannelsTranscodeProgressChannel.broadcast_to(
      transcodable.channel,
      event: 'transcode_progress_changed',
      data: {
        transcodable_id: transcodable.id,
        transcodable_class: transcodable.class.name,
        status: status,
        percent: percent,
        error: error
      }
    )
  end

  def notify_transcode_completed
    return if transcodable.channel.blank?
    return unless completed?

    ChannelsTranscodeProgressChannel.broadcast_to(
      transcodable.channel,
      event: 'transcode_completed',
      data: {
        transcodable_id: transcodable.id,
        transcodable_class: transcodable.class.name,
        status: status,
        percent: percent,
        error: error
      }
    )
  end
end
