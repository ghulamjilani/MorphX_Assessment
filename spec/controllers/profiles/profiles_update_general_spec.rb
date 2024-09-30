# frozen_string_literal: true

require 'spec_helper'

describe ProfilesController, 'PUT :profile' do
  before do
    sign_in current_user, scope: :user
  end

  describe 'PUT :update_general' do
    context 'when given valid credit card info' do
      let(:current_user) { create(:user) }
      let(:found_us_method) { create(:found_us_method) }

      before do
        create(:presenter, user: current_user)
      end

      it 'saves everything' do
        expect(current_user.organization).to be_blank

        put :update_general, params: {
          profile: { user_account_attributes: {
            city: 'Houston',
            country: 'US',
            country_state: 'alabama',
            'found_us_method_id' => found_us_method.id,
            'phone' => '5555555555',
            'tagline' => 'x' * 75,
            'talent_list' => 'sun, football, snow'
          } }
        }
        expect(response).to be_redirect

        current_user.reload
        expect(current_user.user_account.talent_list.sort).to eq(%w[snow football sun].sort)
      end
    end

    context 'when given existing user with completed profile' do
      let(:current_user) { create(:user) }

      it 'saves profile info' do
        expect(ActionMailer::Base.deliveries.count).to eq(0)

        put :update_general, params: { profile: {
          email: current_user.email,
          first_name: 'John',
          last_name: 'Brown',
          display_name: 'jb 754',
          gender: 'male',
          public_display_name_source: 'full_name',
          'birthdate(1i)' => '1956',
          'birthdate(2i)' => '5',
          'birthdate(3i)' => '10'
        } }

        expect(flash.now[:success]).to be_present

        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end
  end
end
