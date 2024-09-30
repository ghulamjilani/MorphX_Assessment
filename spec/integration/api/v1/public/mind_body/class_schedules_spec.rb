# frozen_string_literal: true

require 'swagger_helper'

describe 'Search', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/mind_body/class_schedules' do
    get 'ClassSchedules' do
      tags 'Public::MindBody::ClassSchedules'
      produces 'application/json'
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
