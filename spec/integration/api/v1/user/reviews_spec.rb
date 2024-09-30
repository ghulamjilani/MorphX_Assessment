# frozen_string_literal: true

require 'swagger_helper'

describe 'Reviews', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/reviews' do
    get 'Get model reviews' do
      tags 'User::Reviews'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :reviewable_type, in: :query, type: :string, required: true,
                description: "Valid values are: 'Organization', 'Channel', 'Session', 'Video', 'Recording'"
      parameter name: :reviewable_id, in: :query, type: :integer, required: true
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :created_at_from, in: :query, type: :string,
                description: 'Example: "2021-09-29T00:00:00.000+00:00"'
      parameter name: :created_at_to, in: :query, type: :string, description: 'Example: "2021-09-30T23:59:59.999+00:00"'
      parameter name: :scope, in: :query, type: :string, description: 'Available values: "participant", "organizer"'
      parameter name: :visible, in: :query, type: :boolean
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/reviews/{reviewable_type}/{reviewable_id}' do
    get 'Get model reviews' do
      tags 'User::Reviews'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :reviewable_type, in: :path, type: :string, required: true,
                description: "Valid values are: 'Organization', 'Channel', 'Session', 'Video', 'Recording'"
      parameter name: :reviewable_id, in: :path, type: :integer, required: true
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :offset, in: :query, type: :integer
      parameter name: :limit, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/reviews/current' do
    get 'Show own review for model' do
      tags 'User::Reviews'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :reviewable_type, in: :query, type: :string, required: true,
                description: "Valid values are: 'Session', 'Video', 'Recording'"
      parameter name: :reviewable_id, in: :query, type: :integer, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/reviews/:id' do
    get 'Show specific review for model' do
      tags 'User::Reviews'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :reviewable_type, in: :query, type: :string, required: true,
                description: "Valid values are: 'Session', 'Video', 'Recording'"
      parameter name: :reviewable_id, in: :query, type: :integer, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/reviews/:id' do
    post 'Create review for model' do
      tags 'User::Reviews'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :reviewable_type, in: :query, type: :string, required: true,
                description: "Valid values are: 'Session', 'Video', 'Recording'"
      parameter name: :reviewable_id, in: :query, type: :integer, required: true
      parameter name: :title, in: :query, type: :string
      parameter name: :overall_experience_comment, in: :query, type: :string
      parameter name: :technical_experience_comment, in: :query, type: :string
      parameter name: :immerss_experience, in: :query, type: :string
      parameter name: :quality_of_content, in: :query, type: :string
      parameter name: :presenter_performance, in: :query, type: :string
      parameter name: :video_quality, in: :query, type: :string
      parameter name: :sound_quality, in: :query, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/reviews/:id' do
    put 'Update review' do
      tags 'User::Reviews'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :reviewable_type, in: :query, type: :string, required: true,
                description: "Valid values are: 'Session', 'Video', 'Recording'"
      parameter name: :reviewable_id, in: :query, type: :integer, required: true
      parameter name: :visible, in: :query, type: :boolean,
                description: 'Available only for commentable owner or moderator'
      parameter name: :title, in: :query, type: :string, description: 'Available only for review owner'
      parameter name: :overall_experience_comment, in: :query, type: :string,
                description: 'Available only for review owner'
      parameter name: :technical_experience_comment, in: :query, type: :string,
                description: 'Available only for review owner'
      parameter name: :immerss_experience, in: :query, type: :string, description: 'Available only for review owner'
      parameter name: :quality_of_content, in: :query, type: :string, description: 'Available only for review owner'
      parameter name: :presenter_performance, in: :query, type: :string, description: 'Available only for review owner'
      parameter name: :video_quality, in: :query, type: :string, description: 'Available only for review owner'
      parameter name: :sound_quality, in: :query, type: :string, description: 'Available only for review owner'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/reviews/:id' do
    delete 'Destroy review' do
      tags 'User::Reviews'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
