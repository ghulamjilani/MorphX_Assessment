# frozen_string_literal: true

require 'spec_helper'

describe SharesController do
  before do
    sign_in(current_user, scope: :user)
  end

  describe 'POST :refer_friends' do
    render_views

    let(:current_user) { create(:user) }

    it 'does not fail' do
      post :refer_friends, xhr: true,
                           params: { emails: 'user1@eexample.com,user2@eexample.com,user3@eexample.com,user4@eexample.com,user5@eexample.com,' }

      expect(response).to be_successful
      expect(flash.now[:success1]).to be_present
      expect(User.count).to eq(6)

      expect(TodoAchievement.exists?(user: current_user,
                                     type: TodoAchievement::Types::REFERRED_FIVE_FRIENDS)).to eq(true)
    end
  end

  describe 'POST :increment' do
    context 'when given organization' do
      let!(:organization) { create(:organization, shares_count: 0) }
      let(:current_user) { [organization.user, nil].sample }

      it 'works' do
        expect(organization.reload.shares_count).to eq(0)

        post :increment, xhr: true, params: { model: 'organization', provider: 'facebook', id: organization.id }

        expect(response).to be_successful

        expect(organization.reload.shares_count).to eq(1)
      end
    end

    context 'when given session' do
      let!(:session) { create(:published_session, shares_count: 0) }
      let(:current_user) { [session.organizer, nil].sample }

      it 'works' do
        expect(session.reload.shares_count).to eq(0)

        post :increment, xhr: true, params: { model: 'session', provider: 'facebook', id: session.id }

        expect(response).to be_successful

        expect(session.reload.shares_count).to eq(1)
      end
    end
  end

  describe 'POST :email' do
    context 'when given session' do
      let!(:session) { create(:published_session, shares_count: 0) }
      let(:current_user) { session.organizer }

      it 'works' do
        expect(session.reload.shares_count).to eq(0)

        post :email, xhr: true, params: {
          klass: 'Session',
          model_id: session.id,
          emails: 'user2@unite.live',
          subject: 'Gürhard Brow4423423423 shared a session with you on Unite.',
          body: 'Hey, chec k this out! Yoga2: Yata Durmstrang Institude for Magical Learning 224 http://localhost:3000/Yoga2/Yata+Durmstrang+Institude+for+Magical+Learning+224'
        }
        expect(response).to be_successful

        expect(session.reload.shares_count).to eq(1)
      end
    end
  end
end
