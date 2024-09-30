# frozen_string_literal: true

require 'swagger_helper'

describe 'Videos', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/videos' do
    get 'Get video info' do
      tags 'Public::Videos'
      parameter name: :user_id, in: :query, type: :integer
      parameter name: :room_id, in: :query, type: :integer
      parameter name: :session_id, in: :query, type: :integer
      parameter name: :channel_id, in: :query, type: :integer
      %w[start_at end_at].each do |param|
        parameter name: "#{param}_from".to_sym, in: :query, type: :string, format: 'date-time'
        parameter name: "#{param}_to".to_sym, in: :query, type: :string, format: 'date-time'
      end
      parameter name: :duration_from, in: :query, type: :integer
      parameter name: :duration_to, in: :query, type: :integer
      parameter name: :show_on_home, in: :query, type: :boolean
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'id', 'duration', 'created_at', 'updated_at'. Default: promo weight"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/videos/{id}' do
    get 'Get video details' do
      tags 'Public::Videos'
      parameter name: :id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/public/videos/{video_id}/embeds' do
    get 'Get embeds list' do
      tags 'Public::Videos'
      parameter name: :video_id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
