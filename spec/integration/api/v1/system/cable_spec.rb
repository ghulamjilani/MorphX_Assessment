# frozen_string_literal: true

require 'swagger_helper'

describe 'System::Cable', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/system/cable' do
    post 'Send cable notification' do
      tags 'System'
      description 'Use Authorization header from organization if user password is blank'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true,
                description: 'Generate basic auth token at /service_admin_panel/basic_auth'
      parameter name: :channel, in: :query, type: :string, required: true,
                description: "Available channels are: 'UsersChannel', 'SessionsChannel', 'PaypalDonationsChannel', 'PresenceImmersiveRoomsChannel', 'PresenceSourceRoomsChannel',
                              'PrivateLivestreamRoomsChannel', 'PublicLivestreamRoomsChannel', 'RoomsChannel', 'StreamPreviewsChannel'"
      parameter name: :event, in: :query, type: :string, required: true, description: 'Event name'
      parameter name: :data, in: :query, type: :string, required: false, description: 'Data encoded in json'
      parameter name: :to_object, in: :query, type: :string, required: false,
                description: 'Object class and id in json: {"class":"User","id":1}'

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
