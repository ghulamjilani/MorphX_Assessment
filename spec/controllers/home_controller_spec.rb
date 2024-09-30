# frozen_string_literal: true

require 'spec_helper'

describe HomeController do
  before { sign_in(current_user, scope: :user) }

  let(:all_delivery_methods) { { immersive: 'on', livestream: 'on', vod: 'on' } }
  let(:all_types) { { performance: 'on', instructional: 'on', social: 'on' } }

  describe 'GET :search' do
    let(:channel_with_image) { create(:channel_with_image) }
    let(:current_user) { create(:user) }

    render_views

    context 'with title' do
      let(:session1) { create(:one_on_one_session, channel: channel_with_image, title: 'The Maker bot Replicator 2x') }
      let(:session2) { create(:one_on_one_session, channel: channel_with_image, title: 'Leapfrog Creatr') }
      let(:session3) { create(:one_on_one_session, channel: channel_with_image, title: 'ORD bot Hadron') }

      it 'returns correct result' do
        skip 'temporarily skipped because of low priority'

        session1
        session2
        session3
        channel_with_image.multisearch_reindex # after_commit callback doesn't work in test env :/
        get :search, params: { q: 'bot', delivery_methods: all_delivery_methods, type: all_types }

        expect(response).to be_successful
        expect(assigns(:sessions)).to include session1
        expect(assigns(:sessions)).to include session3
        expect(assigns(:sessions)).to include session2
      end
    end

    context 'with channel tags' do
      let(:channel1) { create(:channel_with_image, tag_list: 'trol,lol,pfff') }
      let(:channel2) { create(:channel_with_image, tag_list: 'trol,pfff,glhf') }
      let(:session1) { create(:one_on_one_session, channel: channel_with_image, title: 'The Maker bot Replicator 2x') }
      let(:session2) { create(:one_on_one_session, title: 'Leapfrog Creatr', channel: channel1) }
      let(:session3) { create(:one_on_one_session, title: 'ORD bot Hadron', channel: channel2) }

      it 'returns correct result' do
        skip 'temporarily skipped because of low priority'

        channel1
        channel2
        session1
        session2
        session3

        # after_commit callback doesn't work in test env :/
        channel1.multisearch_reindex
        channel2.multisearch_reindex

        get :search, params: { q: 'trol pfff', delivery_methods: all_delivery_methods, type: all_types }

        expect(response).to be_successful

        expect(assigns(:sessions)).to include session2
        expect(assigns(:sessions)).to include session3
        expect(assigns(:sessions)).not_to include session1
      end
    end

    context 'with channel description' do
      let(:channel1) { create(:channel_with_image, description: 'trol lol pfff' * 50) }
      let(:session1) { create(:one_on_one_session, channel: channel_with_image, title: 'The Maker bot Replicator 2x') }
      let(:session2) { create(:one_on_one_session, title: 'Leapfrog Creatr', channel: channel1) }
      let(:session3) { create(:one_on_one_session, channel: channel_with_image, title: 'ORD bot Hadron') }

      it 'returns correct result' do
        skip 'temporarily skipped because of low priority'

        channel1
        session1
        session2
        session3
        # after_commit callback doesn't work in test env :/
        channel1.multisearch_reindex

        get :search, params: { q: 'trol', delivery_methods: all_delivery_methods, type: all_types }

        expect(response).to be_successful

        expect(assigns(:sessions)).to include session2
        expect(assigns(:sessions)).not_to include session3
        expect(assigns(:sessions)).not_to include session1
      end
    end

    context 'with channel title' do
      let(:channel1) { create(:channel_with_image, title: 'trol lol pfff') }
      let(:session1) { create(:one_on_one_session, channel: channel_with_image, title: 'The Maker bot Replicator 2x') }
      let(:session2) { create(:one_on_one_session, title: 'Leapfrog Creatr', channel: channel1) }
      let(:session3) { create(:one_on_one_session, channel: channel_with_image, title: 'ORD bot Hadron') }

      it 'returns correct result' do
        skip 'temporarily skipped because of low priority'

        channel1
        session1
        session2
        session3
        # after_commit callback doesn't work in test env :/
        channel1.multisearch_reindex

        get :search, params: { q: 'trol', delivery_methods: all_delivery_methods, type: all_types }

        expect(response).to be_successful

        expect(assigns(:sessions)).to include session2
        expect(assigns(:sessions)).not_to include session3
        expect(assigns(:sessions)).not_to include session1
      end
    end

    context 'with presenter location' do
      let(:presenter1) do
        user = create(:us_user_account).user
        create(:presenter, user: user)
      end

      let(:presenter2) do
        user = create(:user_account, country: 'CA').user
        create(:presenter, user: user)
      end

      let(:channel1) { create(:channel_with_image, presenter: presenter1) }
      let(:channel2) { create(:channel_with_image, presenter: presenter2) }

      let(:session1) { create(:one_on_one_session, channel: channel1) }
      let(:session2) { create(:one_on_one_session, channel: channel2) }
      let(:session3) { create(:one_on_one_session, channel: channel2) }

      let(:us_variants) do
        [
          'united states',
          'united states of america',
          'USA',
          'U.S.',
          'US',
          'U.S.A.'
        ]
      end

      it 'returns correct result' do
        skip 'temporarily skipped because of low priority'

        presenter1
        presenter2

        channel1
        channel2

        session1
        session2
        session3

        get :search, params: { q: us_variants.sample, delivery_methods: all_delivery_methods, type: all_types }
        expect(response).to be_successful

        expect(assigns(:sessions)).not_to include session2
        expect(assigns(:sessions)).not_to include session3
        expect(assigns(:sessions)).to include session1
      end
    end
  end
end
