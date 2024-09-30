# frozen_string_literal: true

require 'swagger_helper'

describe 'Users', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/users/current' do
    get 'Get current user info' do
      tags 'User::Users'
      description 'Get current user info'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/users/current' do
    put 'Update current user info' do
      tags 'User::Users'
      description 'Update current user info'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user1@example.com' },
          password: { type: :string, example: 'abcdef' },
          password_confirmation: { type: :string, example: 'abcdef' },
          birthdate: { type: :string, example: '1989-11-14' },
          first_name: { type: :string, example: 'John' },
          last_name: { type: :string, example: 'Doe' },
          slug: { type: :string, example: 'john-doe' },
          display_name: { type: :string, example: 'John Doe' },
          gender: { type: :string, example: 'male' },
          public_display_name_source: { type: :string, example: 'display_name' },
          time_format: { type: :string, example: '12hour' },
          manually_set_timezone: { type: :string, example: User.available_timezones.first.tzinfo.name },
          currency: { type: :string, example: 'USD' },
          custom_slug_value: { type: :string, example: 'john-the-greatest-doe' },
          language: { type: :string, example: 'en' },
          user_account_attributes: {
            type: :object,
            properties: {
              bio: { type: :string, example: "1.Im a big fan of Hannah...\n
                                              2.I love reading mostly baby sitters club...\n3.Im kind,caring wild,nice, funny,silly...\n
                                              4. I want to be a police officer in the...\n5.My motto is be...\n6. My favorouite actress is Miley...\n
                                              7.I am also outgoing,loud, not afraid to tell the truth about...\n" },
              city: { type: :string, example: 'Houston' },
              country: { type: :string, example: 'DE' },
              country_state: { type: :string, example: 'New York' },
              phone: { type: :string, example: '5555555' },
              contact_email: { type: :string, example: 'user_contact@example.com' }
            }
          }
        }
      }

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
