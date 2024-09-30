# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::ShareController do
  render_views

  describe '.json request format' do
    describe 'GET index:' do
      context 'when given no params' do
        it 'is not successful' do
          get :index, format: :json
          expect(response).not_to be_successful
        end
      end

      context 'when model present' do
        %w[User Channel Session Video Recording].each do |model_type|
          it "contains share info for #{model_type}" do
            model = case model_type
                    when 'Channel'
                      create(:approved_channel)
                    when 'Session'
                      create(:published_livestream_session)
                    when 'Video'
                      create(:video_published, room: create(:room, abstract_session: create(:published_session)))
                    else
                      create(:"#{model_type.downcase}")
                    end
            get :index, format: :json, params: { model_type: model_type, model_id: model.id }
            expect(response.body).to include(model.absolute_path)
            expect(response.body).to include(model.short_url)
          end
        end
      end
    end

    describe 'POST email:' do
      let(:current_user) { create(:user) }
      let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

      context 'when given no user' do
        it 'is not successful' do
          post :email, format: :json
          expect(response).not_to be_successful
        end
      end

      context 'when given no params' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        it 'is not successful' do
          post :email, format: :json
          expect(response).not_to be_successful
        end
      end

      context 'when model present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        %w[User Channel Session Video Recording].each do |model_type|
          # %w(Channel Session).each do |model_type|
          it "share be email for #{model_type}" do
            model = case model_type
                    when 'Channel'
                      create(:approved_channel)
                    when 'Session'
                      create(:published_livestream_session)
                    when 'Video'
                      create(:video_published, room: create(:room, abstract_session: create(:published_session)))
                    else
                      create(:"#{model_type.downcase}")
                    end
            post :email, format: :json,
                         params: { model_type: model_type, model_id: model.id, subject: 'Subject', body: 'Body', emails: Forgery('internet').email_address }
            expect(response).to be_successful
          end
        end
      end
    end
  end
end
