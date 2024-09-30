# frozen_string_literal: true

require 'swagger_helper'

describe 'Session Invited Livestream Participantships', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/session_invited_livestream_participantships' do
    get 'Get invited participantships' do
      tags 'User::SessionInvitedLivestreamParticipantships'
      description 'Get all invited participantships for current user or session'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :room_id, in: :query, type: :integer
      parameter name: :session_id, in: :query, type: :integer
      parameter name: :status, in: :query, type: :string,
                description: "Valid values are: 'accepted', 'rejected', 'pending'."
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/session_invited_livestream_participantships/{id}' do
    get 'Get participantship info' do
      tags 'User::SessionInvitedLivestreamParticipantships'
      description ''
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/session_invited_livestream_participantships' do
    post 'Create room participantship' do
      tags 'User::SessionInvitedLivestreamParticipantships'
      description 'Requires (room_id or session_id) and (user_id or email)'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :room_id, in: :query, type: :string
      parameter name: :session_id, in: :query, type: :string
      parameter name: :user_id, in: :query, type: :integer
      parameter name: :email, in: :query, type: :string

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/session_invited_livestream_participantships/{id}' do
    put 'Update(accept/reject) room participantship' do
      tags 'User::SessionInvitedLivestreamParticipantships'
      description ''
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :status, in: :query, type: :string, required: true,
                description: "Valid values are: 'accepted', 'rejected'"

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/session_invited_livestream_participantships/{id}' do
    delete 'Delete room participantship' do
      tags 'User::SessionInvitedLivestreamParticipantships'
      description ''
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
