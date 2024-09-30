# frozen_string_literal: true

module ModelConcerns
  module Session
    module WebrtcserviceService
      extend ActiveSupport::Concern

      included do
        has_many :webrtcservice_rooms, dependent: :destroy
        has_one :webrtcservice_room, -> { order(created_at: :desc) }, inverse_of: :session, dependent: nil

        scope :interactive, -> { where(service_type: ::Room::ServiceTypes::webrtcservice) }
      end

      def max_number_of_webrtcservice_participants
        49
      end

      def webrtcservice?
        [::Room::ServiceTypes::webrtcservice].include?(service_type)
      end

      def unique_webrtcservice_name
        @unique_webrtcservice_name ||= WebrtcserviceRoom.new(session_id: id).generate_unique_name
      end

      def webrtcservice_client
        @webrtcservice_client ||= Sender::Webrtcservice::Video.client(room)
      end

      def record_webrtcservice_room?
        return false unless Rails.application.credentials.backend.dig(:initialize, :webrtcservice, :video, :records, :enabled)

        do_record?
      end

      def activate_webrtcservice_room
        return false unless webrtcservice?

        webrtcservice_room = webrtcservice_client.room(unique_webrtcservice_name, expected_status: [200, 404])

        return webrtcservice_room.with_indifferent_access if webrtcservice_room.present?

        webrtcservice_room_params = {
          RecordParticipantsOnConnect: record_webrtcservice_room?,
          MaxParticipants: (max_number_of_immersive_participants.to_i + 1)
        }
        webrtcservice_client.create_room(unique_webrtcservice_name, webrtcservice_room_params)
      end

      def remove_webrtcservice_participant(room_member)
        return false unless (webrtcservice_room = webrtcservice_client.room(unique_webrtcservice_name, expected_status: [200, 404]).presence)

        identity = Webrtcservice::Video::Participant.new(room_member: room_member).identity
        webrtcservice_client.disconnect_room_participant(webrtcservice_room['sid'], identity, { expected_status: [200, 202, 404] })
      end
    end
  end
end
