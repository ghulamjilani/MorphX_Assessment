# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::RecordingsController do
  let(:organization) { create(:organization) }
  let(:user) { organization.user }
  let(:participant) { create(:participant, user: user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(user)}" }

  let(:owned_channel1) { create(:listed_channel, organization: organization) }
  let(:owned_channel2) { create(:listed_channel, organization: organization) }
  let!(:uploaded_recording1) { create(:recording_published, title: 'uploaded recording 1', channel: owned_channel1) }
  let!(:uploaded_recording2) { create(:recording_published, title: 'uploaded recording 2', channel: owned_channel1) }
  let!(:uploaded_recording3) { create(:recording_paid, title: 'uploaded recording 3', channel: owned_channel2) }
  let!(:uploaded_recordings) { [uploaded_recording1, uploaded_recording2, uploaded_recording3] }
  let!(:purchased_recording1) { create(:recording_paid, title: 'purchased recording 1') }
  let!(:purchased_recording2) { create(:recording_paid, title: 'purchased recording 2') }
  let!(:purchased_recording3) { create(:recording_paid, title: 'purchased recording 3') }
  let!(:purchased_recordings) { [purchased_recording1, purchased_recording2, purchased_recording3] }
  let!(:recording_member1) { create(:recording_member, participant: participant, recording: purchased_recording1) }
  let!(:recording_member2) { create(:recording_member, participant: participant, recording: purchased_recording2) }
  let!(:recording_member3) { create(:recording_member, participant: participant, recording: purchased_recording3) }
  let!(:accessible_free_recording) { create(:recording_published, title: 'accessible free recording') }
  let!(:not_accessible_paid_recording) { create(:recording_paid, title: 'not accessible paid recording') }
  let(:response_body) { JSON.parse(response.body) }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :index, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when given no params' do
          before do
            get :index, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
          it { expect(response_body.dig('response', 'recordings_type')).to eq('uploaded') }
          it { expect(response_body['pagination']['limit']).to eq(20) }
          it { expect(response_body['pagination']['offset']).to eq(0) }

          it 'includes all uploaded recordings' do
            uploaded_recordings.each do |recording|
              expect(response.body).to include recording.title
            end
          end

          it 'does not include other recordings except uploaded' do
            purchased_recordings.each do |recording|
              expect(response.body).not_to include recording.title
            end
            expect(response.body).not_to include accessible_free_recording.title
            expect(response.body).not_to include not_accessible_paid_recording.title
          end
        end

        context 'when given recordings_type param' do
          context 'when recordings_type set to "uploaded"' do
            before do
              get :index, params: { recordings_type: 'uploaded' }, format: :json
            end

            it { expect(response_body.dig('response', 'recordings_type')).to eq('uploaded') }
          end

          context 'when recordings_type set to "purchased"' do
            before do
              get :index, params: { recordings_type: 'purchased' }, format: :json
            end

            it { expect(response_body.dig('response', 'recordings_type')).to eq('purchased') }

            it 'includes all purchased recordings' do
              purchased_recordings.each do |recording|
                expect(response.body).to include recording.title
              end
            end

            it 'does not include other recordings except purchased' do
              uploaded_recordings.each do |recording|
                expect(response.body).not_to include recording.title
              end
              expect(response.body).not_to include accessible_free_recording.title
              expect(response.body).not_to include not_accessible_paid_recording.title
            end
          end

          context 'when channel_id is set' do
            context 'when recordings_type is set to purchased' do
              before do
                get :index, params: { recordings_type: 'uploaded', channel_id: owned_channel1.id }, format: :json
              end

              it { expect(response).to be_successful }

              it 'includes recordings from specified channel' do
                expect(response.body).to include uploaded_recording1.title
                expect(response.body).to include uploaded_recording2.title
              end

              it 'does not include recordings from other channels' do
                expect(response.body).not_to include uploaded_recording3.title
                expect(response.body).not_to include purchased_recording1.title
                expect(response.body).not_to include purchased_recording2.title
                expect(response.body).not_to include purchased_recording3.title
                expect(response.body).not_to include accessible_free_recording.title
                expect(response.body).not_to include not_accessible_paid_recording.title
              end
            end

            context 'when recordings_type is set to purchased' do
              before do
                get :index, params: { recordings_type: 'purchased', channel_id: purchased_recording1.channel_id },
                            format: :json
              end

              it { expect(response).to be_successful }

              it 'includes recordings from specified channel' do
                expect(response.body).to include purchased_recording1.title
              end

              it 'does not include recordings from other channels' do
                expect(response.body).not_to include purchased_recording2.title
                expect(response.body).not_to include purchased_recording3.title
                expect(response.body).not_to include uploaded_recording1.title
                expect(response.body).not_to include uploaded_recording2.title
                expect(response.body).not_to include uploaded_recording3.title
                expect(response.body).not_to include accessible_free_recording.title
                expect(response.body).not_to include not_accessible_paid_recording.title
              end
            end
          end
        end
      end
    end

    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: uploaded_recording1.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        it 'shows uploaded recording' do
          get :show, params: { id: uploaded_recording1.id }, format: :json
          expect(response).to be_successful
          expect(response.body).to include uploaded_recording1.title
        end

        it 'shows purchased recording' do
          get :show, params: { id: purchased_recording1.id }, format: :json
          expect(response).to be_successful
          expect(response.body).to include purchased_recording1.title
        end

        it 'shows accessible free recording' do
          get :show, params: { id: accessible_free_recording.id }, format: :json
          expect(response).to be_successful
          expect(response.body).to include accessible_free_recording.title
        end

        it 'does not show unaccessible paid recording' do
          get :show, params: { id: not_accessible_paid_recording.id }, format: :json
          expect(response).to have_http_status :unauthorized
          expect(response.body).not_to include not_accessible_paid_recording.title
        end
      end
    end
  end
end
