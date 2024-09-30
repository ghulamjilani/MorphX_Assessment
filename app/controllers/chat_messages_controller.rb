# frozen_string_literal: true

class ChatMessagesController < ActionController::Base
  # see LOAD_STEP variable in views/widgets/_playlist_dependencies/replay_chat_view.js for details
  LOAD_STEP = 10
  # see ChatMessages.prototype.needsPrevious views/widgets/_playlist_dependencies/replay_chat_view.js for details
  PREV_MESSAGES_TO_LOAD = 100

  before_action :set_chat_channel

  def index
    room = Session.find(@chat_channel.session_id).room

    @became_active_at = if (room_video = room.videos.available.order(created_at: :asc).first)
                          Time.zone.parse(room_video.ffmpegservice_starts_at) + room_video.crop_seconds.seconds
                        else
                          room.became_active_at
                        end

    chat_messages = @chat_channel.chat_messages
    previous = nil
    if params[:needsPrevious] == 'true'
      previous =
        chat_messages
        .where(created_at: { '$lt': @became_active_at + (chunk * LOAD_STEP).seconds })
        .order(position: -1)
        .limit(PREV_MESSAGES_TO_LOAD)
    end
    current =
      chat_messages
      .where(created_at: { '$gte': @became_active_at + (chunk * LOAD_STEP).seconds,
                           '$lt': @became_active_at + ((chunk + 1) * LOAD_STEP).seconds })
      .order(position: 1)
    @chat_messages =
      if previous
        previous + current
      else
        current
      end
  end

  private

  def set_chat_channel
    @chat_channel = ChatChannel.find(params[:chat_channel_id])
  end

  def chunk
    params[:chunk].to_i
  end
end
