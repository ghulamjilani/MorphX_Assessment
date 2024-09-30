# frozen_string_literal: true

require 'swagger_helper'

describe 'ChannelInvitedPresenterships', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/channel_invited_presenterships' do
    get 'Get all user channel invited presenterships' do
      tags 'User::ChannelInvitedPresenterships'
      description 'Get all user channel invited presenterships'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :status, in: :query, type: :string, required: false,
                description: 'Available values are: "pending", "accepted", "rejected"'
      parameter name: :channel_id, in: :query, type: :integer, required: false
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'created_at', 'updated_at', 'invitation_sent_at', 'status'. Default: 'invitation_sent_at'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/channel_invited_presenterships/{id}' do
    get 'Get channel invited presentership info' do
      tags 'User::ChannelInvitedPresenterships'
      description ''
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/channel_invited_presenterships/{id}' do
    put 'Update pending channel invited presentership' do
      tags 'User::ChannelInvitedPresenterships'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :status, in: :query, type: :string, required: true,
                description: "Valid values are: 'accepted', 'rejected'"

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
