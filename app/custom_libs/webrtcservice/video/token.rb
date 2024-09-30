# frozen_string_literal: true

module Webrtcservice
  module Video
    class Token
      def self.access_token(room_member:)
        raise 'The user banned from this room' if room_member.banned

        credentials = Rails.application.credentials.backend.dig(:initialize, :webrtcservice, :video)
        raise 'backend:initialize:webrtcservice:video in application credentials is required' unless credentials

        room = room_member.room
        session = room.session
        session.activate_webrtcservice_room

        token = Webrtcservice::JWT::AccessToken.new(
          credentials[:account_sid],
          credentials[:api_key],
          credentials[:api_secret],
          [],
          identity: Webrtcservice::Video::Participant.new(room_member: room_member).identity,
          ttl: seconds_to_room_end(room)
        )
        grant = ::Webrtcservice::JWT::AccessToken::VideoGrant.new
        grant.room = session.unique_webrtcservice_name
        token.add_grant(grant)
        token.to_jwt
      end

      def self.seconds_to_room_end(room)
        seconds = room.actual_end_at.to_i - Time.now.to_i
        (0...(4 * 3600)).cover?(seconds) ? seconds : 4 * 3600
      end
    end
  end
end
