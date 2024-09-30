# frozen_string_literal: true

module Control
  class Room
    def initialize(room)
      @room = room
    end

    def start
      @room.active! # unlock room or re-generate key may raise an error

      if @room.abstract_session.webrtcservice?
        room_data = @room.abstract_session.webrtcservice_client.room(nil, { expected_status: [200, 404] }).with_indifferent_access
        @stream_state = ((room_data[:status] == 'in-progress') ? 'up' : 'off')
      elsif @room.abstract_session.ffmpegservice? && (wa = @room.abstract_session.ffmpegservice_account)
        if wa.sandbox
          wa.stream_up!
        end
      end

      start_record if @room.recorder_type.present? and !@room.recording_started?

      unless SidekiqSystem::Schedule.exists?(SessionJobs::PingLivestream, @room.id)
        SessionJobs::PingLivestream.perform_at(10.seconds.from_now, @room.id)
      end
    end

    def stop
      unless @room.closed?
        @room.closed!
        Rails.cache.delete_matched('invitation/index/*')
        if @room.ffmpegservice? && (wa = @room.ffmpegservice_account)
          wa.stream_off!
          ApiJobs::EnsureFfmpegserviceStreamStopJob.perform_async(@room.id)
        elsif @room.zoom?
          Sender::ZoomLib.new(identity: connected_zoom_account).end_meeting(session.zoom_meeting.meeting_id)
        elsif @room.abstract_session.webrtcservice?
          webrtcservice_room = @room.abstract_session.webrtcservice_room || @room.abstract_session.build_webrtcservice_room
          Control::WebrtcserviceRoom.new(webrtcservice_room).complete_room
        end

        unless @room.recorder_empty?
          stop_record
        end
        delete_streams
        true
      end
    end

    def start_livestream
      ApiJobs::StartFfmpegserviceStream.perform_async(@room.id)
      true
    end

    def start_record
      @room.start_record!
      @stream_state ||= 'off'
      stream_url = nil
      session = @room.abstract_session
      if @room.zoom?
        connected_zoom_account = session.organizer.zoom_identity
        raise 'No Zoom Account found' if connected_zoom_account.blank?

        sender = Sender::ZoomLib.new(identity: connected_zoom_account)
        meeting = sender.meeting(session.zoom_meeting.meeting_id)
        @stream_state = ((meeting['status'] == 'started') ? 'up' : 'off')
      elsif @room.abstract_session.webrtcservice?
        @stream_state = @room.abstract_session.webrtcservice_room&.inprogress? ? 'up' : 'off'
      elsif @room.ffmpegservice? && (wa = @room.ffmpegservice_account)
        @stream_state = wa&.stream_status ? wa.stream_status : 'off'
        if wa&.stream_up?
          stream_url = wa.hls_url
        end
      end

      PrivateLivestreamRoomsChannel.broadcast_to(@room,
                                                 event: 'join-all',
                                                 data: {
                                                   livestream_up: @stream_state.eql?('up'),
                                                   # stream_id: room.stream_name,
                                                   token: '',
                                                   url: stream_url
                                                 })

      PublicLivestreamRoomsChannel.broadcast_to(@room,
                                                event: 'join-all',
                                                data: {
                                                  livestream_up: @stream_state.eql?('up'),
                                                  # stream_id: room.stream_name,
                                                  # url: url,
                                                  token: ''
                                                })
    end

    def pause_record
      @room.pause_record!
    end

    def resume_record
      @room.resume_record!
    end

    def stop_record
      @room.stop_record!
    end

    def delete_streams
      # Video.live_or_precast.where(room_id: @room.id).each do |livestream|
      #   livestream.delete
      # end
    end

    def be_right_back(on = true)
      on = [true, 'true'].include?(on)
      if on
        PresenceImmersiveRoomsChannel.broadcast_to @room, event: 'brb', data: {}
        PrivateLivestreamRoomsChannel.broadcast_to @room, event: 'brb', data: {}
        PublicLivestreamRoomsChannel.broadcast_to @room, event: 'brb', data: {}
      else
        PresenceImmersiveRoomsChannel.broadcast_to @room, event: 'brb-off', data: {}
        PrivateLivestreamRoomsChannel.broadcast_to @room, event: 'brb-off', data: {}
        PublicLivestreamRoomsChannel.broadcast_to @room, event: 'brb-off', data: {}
      end
    end

    # def start_or_resume_record
    #   # if #@vidyo.paused?
    #   #   resume_record
    #   # else
    #   #   start_record
    #   # end
    # end

    def allow_control(room_member_id)
      room_member = @room.room_members.where(kind: 'co_presenter').find(room_member_id)
      room_member.allow_control!
      PresenceImmersiveRoomsChannel.broadcast_to @room, event: 'allow_control', data: { room_member_id: room_member.id }
    end

    def disable_control(room_member_id)
      room_member = @room.room_members.where(kind: 'co_presenter').find(room_member_id)
      room_member.disable_control!
      PresenceImmersiveRoomsChannel.broadcast_to @room, event: 'disable_control',
                                                        data: { room_member_id: room_member.id }
    end

    def mute(room_member_id)
      room_member = @room.room_members.find(room_member_id)
      room_member.mute!
      if (mute_all = @room.room_members.audience.pluck(:mic_disabled).all?)
        @room.mute!
      end

      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'mic-changed',
        data: {
          room_members: [room_member.id],
          status: 'disabled',
          all: mute_all
        }
      )
    end

    def unmute(room_member_id)
      room_member = @room.room_members.find(room_member_id)
      room_member.unmute!
      if (mute_all = @room.room_members.audience.pluck(:mic_disabled).all?(&:!))
        @room.unmute!
      end

      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'mic-changed',
        data: {
          room_members: [room_member.id],
          status: 'enabled',
          all: mute_all
        }
      )
    end

    # def mute_source(source_id)
    #   room_member = @room.room_members.find_by!(source_id: source_id)
    #   room_member.mute!
    #   Sender::Portal::Interactive.mic('disabled', @room, [room_member.source_id], false)
    # end

    # def unmute_source(source_id)
    #   room_member = @room.room_members.find_by!(source_id: source_id)
    #   room_member.unmute!
    #   Sender::Portal::Interactive.mic('enabled', @room, [room_member.source_id], false)
    # end

    def mute_all
      room_members = @room.room_members.audience
      @room.mute!
      room_members.update_all(mic_disabled: true)
      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'mic-changed',
        data: {
          room_members: room_members.pluck(:id),
          users: room_members.for_users.pluck(:abstract_user_id),
          status: 'disabled',
          all: true
        }
      )
    end

    def unmute_all
      room_members = @room.room_members.audience
      @room.unmute!
      room_members.update_all(mic_disabled: false)
      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'mic-changed',
        data: {
          room_members: room_members.pluck(:id),
          users: room_members.for_users.pluck(:abstract_user_id),
          status: 'enabled',
          all: true
        }
      )
    end

    def start_video(room_member_id)
      room_member = @room.room_members.find(room_member_id)
      room_member.video_enable!
      if (start_all = @room.room_members.audience.pluck(:video_disabled).all?(&:!))
        @room.video_enable!
      end

      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'video-changed',
        data: {
          room_members: [room_member.id],
          status: 'enabled',
          all: start_all
        }
      )
    end

    def stop_video(room_member_id)
      room_member = @room.room_members.find(room_member_id)
      room_member.video_disable!

      if (stop_all = @room.room_members.audience.pluck(:video_disabled).all?)
        @room.video_disable!
      end

      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'video-changed',
        data: {
          room_members: [room_member.id],
          status: 'disabled',
          all: stop_all
        }
      )
    end

    # def start_video_source(source_id)
    #   room_member = @room.room_members.find_by!(source_id: source_id)
    #   room_member.video_enable!
    #   Sender::Portal::Interactive.video('enabled', @room, [room_member.source_id], false)
    # end

    # def stop_video_source(source_id)
    #   room_member = @room.room_members.find_by!(source_id: source_id)
    #   room_member.video_disable!
    #   Sender::Portal::Interactive.video('disabled', @room, [room_member.source_id], false)
    # end

    def start_all_videos
      room_members = @room.room_members.audience

      @room.video_enable!
      room_members.update_all(video_disabled: false)

      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'video-changed',
        data: {
          room_members: room_members.pluck(:id),
          users: room_members.for_users.pluck(:abstract_user_id),
          status: 'enabled',
          all: true
        }
      )
    end

    def stop_all_videos
      room_members = @room.room_members.audience
      @room.video_disable!
      room_members.update_all(video_disabled: true)

      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'video-changed',
        data: {
          room_members: room_members.pluck(:id),
          users: room_members.for_users.pluck(:abstract_user_id),
          status: 'disabled',
          all: true
        }
      )
    end

    def enable_backstage(room_member_id)
      room_member = @room.room_members.audience.find(room_member_id)

      room_member.backstage_enable!
      if (all = @room.room_members.audience.pluck(:backstage).all?)
        @room.backstage_enable!
      end

      unless @room.active?
        PresenceImmersiveRoomsChannel.broadcast_to @room, event: 'join',
                                                          data: { room_members: [room_member.id] }
      end

      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'backstage-changed',
        data: {
          room_members: [room_member.id],
          users: (room_member.guest? ? [] : [room_member.abstract_user_id]),
          status: 'enabled',
          all: all
        }
      )

      return if room_member.guest?

      UsersChannel.broadcast_to(
        room_member.abstract_user,
        event: 'backstage-update-join',
        data: {
          message: "Presenter #{@room.presenter_user.public_display_name} has invited you to join him backstage",
          room_id: @room.id,
          now: Time.now.to_i,
          start_at: @room.actual_start_at.to_i
        }
      )
    end

    def disable_backstage(room_member_id)
      room_member = @room.room_members.audience.find(room_member_id)
      room_member.backstage_disable!
      if (stop_all = @room.room_members.audience.pluck(:backstage).all?(&:!))
        @room.backstage_disable!
      end

      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'backstage-changed',
        data: {
          room_members: [room_member.id],
          users: [room_member.abstract_user_id],
          status: 'disabled',
          all: stop_all
        }
      )

      return if room_member.guest?

      UsersChannel.broadcast_to(
        room_member.abstract_user,
        event: 'backstage-update-join',
        data: {
          message: "Presenter #{@room.presenter_user.public_display_name} has invited you to join him backstage",
          room_id: @room.id,
          now: Time.now.to_i,
          start_at: @room.abstract_session.start_at.to_i
        }
      )
    end

    def enable_all_backstage
      room_members = @room.room_members.audience

      @room.backstage_enable!
      room_members.update_all(backstage: true)

      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'backstage-changed',
        data: {
          room_members: room_members.pluck(:id),
          users: room_members.for_users.pluck(:abstract_user_id),
          status: 'enabled',
          all: true
        }
      )

      unless @room.active?
        PresenceImmersiveRoomsChannel.broadcast_to @room, event: 'join',
                                                          data: { users: room_members.for_users.pluck(:abstract_user_id) }
      end

      display_name = @room.presenter_user.public_display_name
      room_members.each do |room_member|
        next if room_member.guest?

        UsersChannel.broadcast_to(
          room_member.abstract_user,
          event: 'backstage-update-join',
          data: {
            message: "Presenter #{display_name} has invited you to join him backstage",
            room_id: @room.id,
            now: Time.now.to_i,
            start_at: @room.actual_start_at.to_i
          }
        )
      end
    end

    def disable_all_backstage
      room_members = @room.room_members.audience

      @room.backstage_disable!
      room_members.update_all(backstage: false)

      PresenceImmersiveRoomsChannel.broadcast_to(
        @room,
        event: 'backstage-changed',
        data: {
          room_members: room_members.pluck(:id),
          users: room_members.for_users.pluck(:abstract_user_id),
          status: 'disabled',
          all: true
        }
      )

      display_name = @room.presenter_user.public_display_name
      room_members.each do |room_member|
        next if room_member.guest?

        UsersChannel.broadcast_to(
          room_member.abstract_user,
          event: 'backstage-update-join',
          data: {
            message: "Presenter #{display_name} has invited you to join him backstage",
            room_id: @room.id,
            now: Time.now.to_i,
            start_at: @room.abstract_session.start_at.to_i
          }
        )
      end
    end

    def ban_kick(room_member_id, ban_reason_id = nil)
      banned_member = RoomMember.find(room_member_id)
      banned_member.update(banned: true, ban_reason_id: ban_reason_id)

      Webrtcservice::RoomJobs::RemoveParticipantJob.perform_async(banned_member.id)
    end

    def unban(room_member_id)
      banned_member = RoomMember.find(room_member_id)
      banned_member.update(banned: false, ban_reason_id: nil)
    end

    def pin(room_member_ids)
      @room.room_members.where(id: room_member_ids).update_all(pinned: true)

      @room.cable_pinned_notification
    end

    def pin_only(room_member_ids)
      @room.room_members.where.not(id: room_member_ids).update_all(pinned: false)
      @room.room_members.where(id: room_member_ids).update_all(pinned: true)

      @room.cable_pinned_notification
    end

    def unpin(room_member_ids)
      @room.room_members.where(id: room_member_ids).update_all(pinned: false)

      @room.cable_pinned_notification
    end

    def unpin_all
      @room.room_members.update_all(pinned: false)

      @room.cable_pinned_notification
    end

    def toggle_share
      @room.update(is_screen_share_available: !@room.is_screen_share_available)
    end
  end
end
