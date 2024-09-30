# frozen_string_literal: true

require 'spec_helper'

describe DashboardsController do
  describe 'GET :show' do
    render_views

    let(:channel) { create(:listed_channel) }

    before do
      sign_in current_user, scope: :user
    end

    describe '.html request format' do
      before do
        get :show, format: :html
      end

      context 'when given channel organizer' do
        let(:current_user) { channel.organizer }

        it { expect { get :show, format: :html }.not_to raise_error }
        it { expect(response).to be_redirect }
      end

      context 'when given user with no current organization' do
        let(:current_user) { create(:user) }

        it { expect { get :show, format: :html }.not_to raise_error }
        it { expect(response).to be_redirect }
      end

      context 'when given organization guest member' do
        let(:current_user) { create(:organization_membership_guest, organization: channel.organization).user }

        it { expect { get :show, format: :html }.not_to raise_error }
        it { expect(response).to be_redirect }
      end

      context 'when given organization participant' do
        let(:current_user) { create(:organization_membership, organization: channel.organization).user }

        it { expect { get :show, format: :html }.not_to raise_error }
        it { expect(response).to be_redirect }
      end
    end
  end

  describe 'GET :replays' do
    render_views

    let(:channel) { create(:listed_channel) }

    before do
      sign_in current_user, scope: :user
    end

    describe '.html request format' do
      before do
        get :replays, format: :html
      end

      context 'when given channel organizer' do
        let(:current_user) { channel.organizer }

        it { expect { get :replays, format: :html }.not_to raise_error }
        it { expect(response).to be_successful }
      end

      context 'when given user with no current organization' do
        let(:current_user) { create(:user) }

        it { expect { get :replays, format: :html }.not_to raise_error }
        it { expect(response).to be_successful }
      end

      context 'when given organization guest member' do
        let(:current_user) { create(:organization_membership_guest, organization: channel.organization).user }

        it { expect { get :replays, format: :html }.not_to raise_error }
        it { expect(response).to be_successful }
      end

      context 'when given organization participant' do
        let(:current_user) { create(:organization_membership, organization: channel.organization).user }

        it { expect { get :replays, format: :html }.not_to raise_error }
        it { expect(response).to be_successful }
      end
    end
  end

  describe 'GET :uploads' do
    render_views

    let(:channel) { create(:listed_channel) }

    before do
      sign_in current_user, scope: :user
    end

    describe '.html request format' do
      before do
        get :uploads, format: :html
      end

      context 'when given channel organizer' do
        let(:current_user) { channel.organizer }

        it { expect { get :uploads, format: :html }.not_to raise_error }
        it { expect(response).to be_successful }
      end

      context 'when given user with no current organization' do
        let(:current_user) { create(:user) }

        it { expect { get :uploads, format: :html }.not_to raise_error }
        it { expect(response).to be_successful }
      end

      context 'when given organization guest member' do
        let(:current_user) { create(:organization_membership_guest, organization: channel.organization).user }

        it { expect { get :uploads, format: :html }.not_to raise_error }
        it { expect(response).to be_successful }
      end

      context 'when given organization participant' do
        let(:current_user) { create(:organization_membership, organization: channel.organization).user }

        it { expect { get :uploads, format: :html }.not_to raise_error }
        it { expect(response).to be_successful }
      end
    end
  end
end
