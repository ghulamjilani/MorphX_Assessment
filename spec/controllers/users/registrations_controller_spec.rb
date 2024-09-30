# frozen_string_literal: true

require 'spec_helper'

describe Users::RegistrationsController do
  describe 'POST :create' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      expect(User.count).to be_zero
    end

    context 'when given non-unique full/last name' do
      let!(:user) { create(:user, first_name: 'John', last_name: 'Brown', display_name: nil) }

      it 'does not fail hard' do
        post :create, params: { user: {
          first_name: 'John',
          last_name: 'Brown',
          gender: User::Genders::MALE,
          'birthdate(1i)' => '1950',
          'birthdate(2i)' => '11',
          'birthdate(3i)' => '29',
          email: 'hey@gmail.com',
          password: 'Abcdef123!'
        }, format: :json }
        expect(response.status).to be 201
      end
    end

    context 'when given and valid unique user data' do
      let!(:user) { create(:user, first_name: 'John', last_name: 'Brown', display_name: 'Isabel Wilner') }

      it 'creates user' do
        expect do
          post :create, params: { user: {
            first_name: 'Isabel',
            last_name: 'Wilner',
            gender: User::Genders::MALE,
            'birthdate(1i)' => '1995',
            'birthdate(2i)' => '2',
            'birthdate(3i)' => '2',
            email: 'Izzy.Wizzy@outlook.com',
            password: 'Abcdef123!'
          } }, format: :json

          expect(response.status).to be 201
        end.to change(User, :count).from(1).to(2)
      end
    end
  end
end
