# frozen_string_literal: true

require 'swagger_helper'

describe 'RoomMembers', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/rooms/{room_id}/room_members' do
    get 'Get room members' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at'. Default: 'created_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/mute_all' do
    post 'Mute all room members' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/unmute_all' do
    post 'Unmute all room members' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/start_all_videos' do
    post 'Start videos for all room members' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/stop_all_videos' do
    post 'Stop videos for all room members' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/enable_all_backstage' do
    post 'Enable backstage for all room members' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/enable_all_backstage' do
    post 'Disable backstage for all room members' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/{id}/ban_kick' do
    post 'Ban+kick room member' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :ban_reason_id, in: :query, type: :integer, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/{id}/unban' do
    put 'Unban room member' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/{id}/allow_control' do
    post 'Allow control to room member' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true, description: 'room member user_id'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/{id}/disable_control' do
    post 'Disable room control for room member' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true, description: 'room member user_id'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/{id}/mute' do
    post 'Mute room member' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true, description: 'room member user_id'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/{id}/unmute' do
    post 'Unmute room member' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true, description: 'room member user_id'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/{id}/start_video' do
    post 'Start video for room member' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true, description: 'room member user_id'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/{id}/stop_video' do
    post 'Stop video for room member' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true, description: 'room member user_id'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/{id}/enable_backstage' do
    post 'Enable backstage for room member' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true, description: 'room member user_id'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/{id}/disable_backstage' do
    post 'Disable backstage for room member' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true, description: 'room member user_id'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/pin' do
    post 'Pin specified users' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :room_member_ids, in: :query, type: :string, required: true, description: 'id or array of ids'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/pin_only' do
    post 'Pin specified users and unpin others' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :room_member_ids, in: :query, type: :string, required: true, description: 'id or array of ids'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/unpin' do
    post 'Unpin specified users' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true
      parameter name: :room_member_ids, in: :query, type: :string, required: true, description: 'id or array of ids'

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/rooms/{room_id}/room_members/unpin_all' do
    post 'Unpin all users' do
      tags 'User::RoomMembers'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :room_id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
