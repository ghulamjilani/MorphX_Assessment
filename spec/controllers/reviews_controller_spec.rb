# frozen_string_literal: true

require 'spec_helper'

describe ReviewsController do
  before { sign_in current_user, scope: :user }

  describe 'POST :rate' do
    render_views
    context 'when given session organizer' do
      let(:session) { create(:immersive_session) }

      let(:current_user) { session.organizer }

      it 'is not allowed to rate session' do
        post :rate,
             params: { model_id: session.id, klass: 'Session', score: 3, dimension: Session::RateKeys::QUALITY_OF_CONTENT }, format: :js
        expect(response).not_to be_successful
      end
    end

    context 'when given paid participant and finished session' do
      let(:current_user) { create(:participant).user }
      let(:session) { create(:immersive_session).tap { |s| s.start_at = 1.day.ago; s.save(validate: false) } }

      before { session.immersive_participants << current_user.participant }

      context 'when given valid parameters' do
        context 'when rates session and can change its own rate' do
          before do
            post :rate,
                 params: { model_id: session.id, klass: 'Session', score: 3, dimension: Session::RateKeys::QUALITY_OF_CONTENT }, format: :js

            post :rate,
                 params: { model_id: session.id, klass: 'Session', score: 5, dimension: Session::RateKeys::QUALITY_OF_CONTENT }, format: :js
          end
          it 'something expect' do
            expect(response).to be_successful

            expect(Rate.count).to eq(1)
            Session.update_all({ status: 'published' })
            expect(session.reload.channel.average.avg).to eq(5.0)
          end

          describe 'after rating a session' do
            before { expect(session.reviews.count).to eq(0) }

            it 'creates review comment' do
              post :comment,
                   params: { model_id: session.id, klass: 'Session', comment: { overall_experience_comment: 'foo', title: 'bar' } }, format: :js

              expect(response).to be_successful

              expect(session.reviews.count).to eq(1)
            end

            it 'can update given review comment' do
              post :comment,
                   params: { model_id: session.id, klass: 'Session', comment: { overall_experience_comment: 'foo', title: 'bar' } }, format: :js
              expect(response).to be_successful
              expect(session.reviews.count).to eq(1)

              post :comment,
                   params: { model_id: session.id, klass: 'Session', comment: { overall_experience_comment: 'baz', title: 'qux' } }, format: :js
              expect(response).to be_successful
              expect(session.reload.reviews.count).to eq(1)
            end
          end
        end
      end

      context 'when attempting fraud rate' do
        it 'does not rate session with score greater than 10' do
          post :rate,
               params: { model_id: session.id, klass: 'Session', score: (Session::RATING_MAX_START + 1), dimension: Session::RateKeys::QUALITY_OF_CONTENT }, format: :js
          expect(response).not_to be_successful
        end
      end
    end
  end
end
