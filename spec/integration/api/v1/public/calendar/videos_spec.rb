# frozen_string_literal: true

require 'swagger_helper'

describe 'Videos', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/calendar/videos' do
    get 'Get video info' do
      tags 'Public::Calendar::Videos'
      parameter name: :channel_id, in: :query, type: :integer
      %w[start_at end_at].each do |param|
        parameter name: "#{param}_from".to_sym, in: :query, type: :string, format: 'date-time'
        parameter name: "#{param}_to".to_sym, in: :query, type: :string, format: 'date-time'
      end
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
