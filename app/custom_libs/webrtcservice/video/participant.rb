# frozen_string_literal: true

module Webrtcservice
  module Video
    class Participant
      attr_reader :room, :user, :room_member

      module RoleCodes
        PRESENTER = 'P'
        CO_PRESENTER = 'C'
        PARTICIPANT = 'U'

        ALL = [PRESENTER, CO_PRESENTER, PARTICIPANT].freeze
      end

      def initialize(room_member:)
        @room_member = room_member
        @user = room_member.abstract_user unless room_member.guest?
        @room = room_member.room
      end

      def identity
        role_code = case role
                    when 'presenter'
                      RoleCodes::PRESENTER
                    when 'co_presenter'
                      RoleCodes::CO_PRESENTER
                    when 'participant'
                      RoleCodes::PARTICIPANT
                    else
                      raise 'unprocessible user role'
                    end

        {
          id: @user&.id,
          mid: @room_member.id,
          rl: role_code
        }.to_json
      end

      def role
        @role ||= @room_member.guest? ? 'participant' : @room.role_for(user: @user)
      end

      def self.decode_identity(identity)
        JSON.parse(identity).with_indifferent_access
      rescue StandardError => e
        {}
      end
    end
  end
end
