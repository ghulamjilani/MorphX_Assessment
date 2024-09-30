# frozen_string_literal: true

require 'swagger_helper'

describe 'Videos', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/videos' do
    get 'Get videos for current user' do
      tags 'User::Videos'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :user_id, in: :query, type: :integer
      parameter name: :channel_id, in: :query, type: :integer
      parameter name: :room_id, in: :query, type: :integer
      parameter name: :session_id, in: :query, type: :integer
      parameter name: :start_at_from, in: :query, type: :string
      parameter name: :start_at_to, in: :query, type: :string
      parameter name: :end_at_from, in: :query, type: :string
      parameter name: :end_at_to, in: :query, type: :string
      parameter name: :duration_from, in: :query, type: :integer
      parameter name: :duration_to, in: :query, type: :integer
      parameter name: :show_on_home, in: :query, type: :boolean
      parameter name: :order_by, in: :query, type: :string,
                description: 'Valid values are: "id", "duration", "created_at", "updated_at". Default: "created_at"'
      parameter name: :order, in: :query, type: :string, description: 'Valid values are: "asc", "desc". Default: "asc"'
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
