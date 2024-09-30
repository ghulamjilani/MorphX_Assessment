# frozen_string_literal: true

require 'swagger_helper'

describe 'SystemThemes', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/system_themes' do
    get 'Get themes info' do
      tags 'User::SystemThemes'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
  path '/api/v1/user/system_themes/{id}' do
    get 'Get theme info' do
      tags 'User::SystemThemes'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
  path '/api/v1/user/system_themes/{id}' do
    put 'Update theme info' do
      tags 'User::SystemThemes'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string
      parameter name: :theme, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Dark Theme', required: true },
          custom_css: { type: :string, example: '.main {color: black}' },
          is_default: { type: :boolean, example: true },
          system_theme_variables_attributes: {
            type: :array,
            items: {
              type: :object,
              properties: {
                id: { type: :integer, example: 1, required: false },
                name: { type: :string, example: 'main color', required: true },
                property: { type: :string, example: 'siteColorMain', required: true },
                value: { type: :string, example: '#F23535', required: true },
                group_name: { type: :string, example: 'background', required: true },
                state: { type: :string, example: 'main', required: true },
                _destroy: { type: :boolean, example: true, required: false }
              }
            }
          }
        }
      }

      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
