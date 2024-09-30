# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::NotificationsController do
  let(:user) { create(:user) }
  let(:auth_header_value) { "Bearer #{JwtAuth.user(user)}" }
  let(:unread_notifications) { create_list(:unread_notification, 3, notified_object: user) }

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
            get :index, params: {}, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when given limit param' do
          let(:response_body) { JSON.parse(response.body) }

          before do
            get :index, params: { limit: 1 }, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end

        context 'when given limit and offset params' do
          let(:response_body) { JSON.parse(response.body) }

          before do
            get :index, params: { limit: 1, offset: 1 }, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end

    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: unread_notifications.sample.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
          get :show, params: { id: unread_notifications.first.id }, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'POST mark_as_read:' do
      context 'when JWT missing' do
        it 'returns 401' do
          post :mark_as_read, params: { id: [unread_notifications.sample.id] }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when id param set to specific id' do
          it 'marks notifications as read' do
            post :mark_as_read, params: { id: unread_notifications.sample.id }, format: :json
            expect(response).to be_successful
          end
        end

        context 'when id param set to array of ids' do
          it 'marks notifications as read' do
            post :mark_as_read, params: { id: [unread_notifications.sample.id] }, format: :json
            expect(response).to be_successful
          end
        end

        context 'when id param set to "all"' do
          it 'marks notifications as read' do
            post :mark_as_read, params: { id: 'all' }, format: :json
            expect(response).to be_successful
          end
        end
      end
    end

    describe 'POST mark_as_unread:' do
      context 'when JWT missing' do
        it 'returns 401' do
          post :mark_as_unread, params: { id: [unread_notifications.sample.id] }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when id param set to specific id' do
          it 'marks notifications as unread' do
            post :mark_as_unread, params: { id: unread_notifications.sample.id }, format: :json
            expect(response).to be_successful
          end
        end

        context 'when id param set to array of ids' do
          it 'marks notifications as unread' do
            post :mark_as_unread, params: { id: [unread_notifications.sample.id] }, format: :json
            expect(response).to be_successful
          end
        end

        context 'when id param set to "all"' do
          it 'marks notifications as unread' do
            post :mark_as_unread, params: { id: 'all' }, format: :json
            expect(response).to be_successful
          end
        end
      end
    end

    describe 'DELETE destroy:' do
      context 'when JWT missing' do
        it 'returns 401' do
          delete :destroy, params: { id: [unread_notifications.sample.id] }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        context 'when id param set to specific id' do
          it 'destroys notifications' do
            delete :destroy, params: { id: unread_notifications.sample.id }, format: :json
            expect(response).to be_successful
          end
        end

        context 'when id param set to array of ids' do
          it 'destroys notifications' do
            delete :destroy, params: { id: [unread_notifications.sample.id] }, format: :json
            expect(response).to be_successful
          end
        end

        context 'when id param set to "all"' do
          it 'destroys notifications' do
            delete :destroy, params: { id: 'all' }, format: :json
            expect(response).to be_successful
          end
        end
      end
    end
  end
end
