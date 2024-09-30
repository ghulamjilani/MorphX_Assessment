# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::SessionsController do
  let(:channel) { create(:listed_channel) }
  let(:session) { create(:session_with_livestream_only_delivery) }
  let(:session2) { create(:immersive_session_with_recorded_delivery) }
  let(:session3) { create(:immersive_session_with_recorded_delivery, channel: channel) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when no params present' do
        it 'does not fail and returns valid json' do
          get :index, format: :json

          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end

      context 'when given params' do
        before do
          session
          session2
          session3

          get :index, params: params, format: :json
        end

        context 'when channel filter is set' do
          let(:params) { { channel_id: session.channel_id } }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect(response.body).to include session.title
            expect(response.body).not_to include session2.title
          end
        end

        context 'when organization filter is set' do
          let(:params) { { organization_id: session3.channel.organization_id } }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect(response.body).to include session3.title
            expect(response.body).not_to include session2.title
          end
        end

        context 'when owner filter is set' do
          let(:params) { { owner_id: session3.channel.organization.user_id } }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect(response.body).to include session3.title
            expect(response.body).not_to include session2.title
          end
        end

        context 'when limit param is set' do
          let(:params) { { limit: 1 } }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect(JSON.parse(response.body)['response']['sessions'].size).to eq(1)
            expect(JSON.parse(response.body)['pagination']['limit']).to eq 1
          end
        end

        context 'when offset param is set' do
          let(:params) { { limit: 1, offset: 1 } }

          it 'does not fail and returns valid json' do
            expect(response).to be_successful
            expect(JSON.parse(response.body)['pagination']['current_page']).to eq 2
          end
        end

        context 'when given end_at_from param' do
          let(:params) { { end_at_from: 5.minutes.ago.utc.to_fs(:rfc3339) } }

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error }
        end

        context 'when given end_at_to param' do
          let(:params) { { end_at_to: 5.minutes.ago.utc.to_fs(:rfc3339) } }

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error }
        end

        context 'when given start_at_from param' do
          let(:params) { { start_at_from: 5.minutes.ago.utc.to_fs(:rfc3339) } }

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error }
        end

        context 'when given start_at_to param' do
          let(:params) { { start_at_to: 5.minutes.ago.utc.to_fs(:rfc3339) } }

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error }
        end

        context 'when given duration_from param' do
          let(:params) { { duration_from: (5..180).step(5).to_a.sample } }

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error }
        end

        context 'when given duration_to param' do
          let(:params) { { duration_to: (10..180).step(5).to_a.sample } }

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error }
        end
      end
    end

    describe 'GET show:' do
      context 'when session exsits' do
        it 'does not fail and returns valid json' do
          get :show, params: { id: session.id }, format: :json

          expect(response).to be_successful
          expect { JSON.parse(response.body) }.not_to raise_error, response.body
        end
      end
    end
  end
end
