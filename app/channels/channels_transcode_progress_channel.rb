# frozen_string_literal: true

class ChannelsTranscodeProgressChannel < ApplicationCable::Channel
  EVENTS = {
    transcode_progress_changed: 'Broadcast transcodable transcode progress. Data: { transcodable_id: transcodable.id, transcodable_class: transcodable.class.name, status: \'completed\', percent: 100, error: 0 }',
    transcode_completed: 'Broadcast transcodable transcode completed event. Data: { transcodable_id: transcodable.id, transcodable_class: transcodable.class.name, status: \'completed\', percent: 100, error: 0 }'
  }.freeze

  def subscribed
    return unless (channel = ::Channel.find_by(id: params[:data]))
    return unless current_ability.can?(:transcode_recording, channel) || current_ability.can?(:transcode_replay, channel)

    stream_for channel
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def current_ability
    @current_ability ||= AbilityLib::ChannelAbility.new(current_user)
  end
end
