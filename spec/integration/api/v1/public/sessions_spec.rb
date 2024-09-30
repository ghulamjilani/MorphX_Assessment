# frozen_string_literal: true

require 'swagger_helper'

describe 'Sessions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/sessions' do
    get 'List all sessions' do
      tags 'Public::Sessions'
      parameter name: :channel_id, in: :query, type: :integer
      parameter name: :presenter_id, in: :query, type: :integer
      parameter name: :organization_id, in: :query, type: :integer
      parameter name: :owner_id, in: :query, type: :integer
      %w[start_at end_at].each do |param|
        parameter name: "#{param}_from".to_sym, in: :query, type: :string, format: 'date-time'
        parameter name: "#{param}_to".to_sym, in: :query, type: :string, format: 'date-time'
      end
      parameter name: :duration_from, in: :query, type: :integer
      parameter name: :duration_to, in: :query, type: :integer
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'start_at', 'end_at'. Default: 'start_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/sessions/{id}' do
    get 'Get session info' do
      tags 'Public::Sessions'
      parameter name: :id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/sessions/{session_id}/embeds' do
    get 'Get embeds list' do
      tags 'Public::Sessions'
      parameter name: :session_id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
