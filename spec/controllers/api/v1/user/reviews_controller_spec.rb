# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::ReviewsController do
  let(:review) { create(:session_review_with_mandatory_rates, title: SecureRandom.alphanumeric(40)) }
  let(:reviewable) { review.commentable }

  render_views

  describe '.json request format' do
    let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'GET index:' do
      let(:current_user) { create(:user) }
      let(:params) { { reviewable_type: reviewable.class.to_s, reviewable_id: reviewable.id } }

      before do
        review
        get :index, params: params, format: :json
      end

      context 'when given session as reviewable' do
        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given recording as reviewable' do
        let(:review) { create(:recording_review_with_mandatory_rates) }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when review is from presenter' do
        let(:review) { create(:session_review_from_presenter, title: SecureRandom.alphanumeric(40)) }

        it { expect(response.body).not_to include(review.title) }

        context 'when current user is review author' do
          let(:current_user) { review.user }

          it { expect(response.body).to include(review.title) }
        end
      end

      context 'when review is from participant and visible' do
        it { expect(response.body).to include(review.title) }
      end

      context 'when review is from participant and hidden' do
        let(:review) do
          create(:session_review_with_mandatory_rates, visible: false, title: SecureRandom.alphanumeric(40))
        end

        it { expect(response.body).not_to include(review.title) }

        context 'when current user is review author' do
          let(:current_user) { review.user }

          it { expect(response.body).not_to include(review.title) }
        end
      end

      context 'when given created_at_from and created_at_to params that include review' do
        let(:params) do
          {
            reviewable_type: reviewable.class.to_s,
            reviewable_id: reviewable.id,
            created_at_from: (review.created_at - 1.day).utc.to_fs(:rfc3339),
            created_at_to: (review.created_at + 1.day).utc.to_fs(:rfc3339)
          }
        end

        it { expect(response.body).to include(review.title) }
      end

      context 'when given created_at_from and created_at_to params that don\'t include review' do
        let(:params) do
          {
            reviewable_type: reviewable.class.to_s,
            reviewable_id: reviewable.id,
            created_at_from: (review.created_at - 2.days).utc.to_fs(:rfc3339),
            created_at_to: (review.created_at - 1.day).utc.to_fs(:rfc3339)
          }
        end

        it { expect(response.body).not_to include(review.title) }
      end

      context 'when given visible param' do
        let(:review) do
          create(:session_review_with_mandatory_rates, visible: false, title: SecureRandom.alphanumeric(40))
        end
        let(:params) do
          {
            reviewable_type: reviewable.class.to_s,
            reviewable_id: reviewable.id,
            visible: visible
          }
        end

        context 'when visible set to true and current user is review author' do
          let(:visible) { true }
          let(:current_user) { review.user }

          it { expect(response.body).not_to include(review.title) }
        end

        context 'when visible set to false and current user is review author' do
          let(:visible) { false }
          let(:current_user) { review.user }

          it { expect(response.body).not_to include(review.title) }
        end

        context 'when visible set to true and current user is reviewable author' do
          let(:visible) { true }
          let(:current_user) { review.commentable.organizer }

          it { expect(response.body).not_to include(review.title) }
        end

        context 'when visible set to false and current user is reviewable author' do
          let(:visible) { false }
          let(:current_user) { review.commentable.organizer }

          it { expect(response.body).to include(review.title) }
        end

        context 'when visible set to false and current user is random user' do
          let(:visible) { false }
          let(:current_user) { create(:user) }

          it { expect(response.body).not_to include(review.title) }
        end
      end

      context 'when given scope param set to participant' do
        let(:params) do
          {
            reviewable_type: reviewable.class.to_s,
            reviewable_id: reviewable.id,
            scope: 'participant'
          }
        end
        let(:session_review_from_presenter) do
          create(:session_review_from_presenter, title: SecureRandom.alphanumeric(40), commentable: review.commentable,
                                                 user: review.commentable.organizer)
        end
        let(:current_user) { session_review_from_presenter.user }

        it { expect(response.body).not_to include(session_review_from_presenter.title) }

        it { expect(response.body).to include(review.title) }
      end

      context 'when given scope param set to organizer' do
        let(:params) do
          {
            reviewable_type: reviewable.class.to_s,
            reviewable_id: reviewable.id,
            scope: 'organizer'
          }
        end
        let(:session_review_from_presenter) do
          create(:session_review_from_presenter, title: SecureRandom.alphanumeric(40), commentable: review.commentable,
                                                 user: review.commentable.organizer)
        end
        let(:current_user) { session_review_from_presenter.user }

        it { expect(response.body).to include(session_review_from_presenter.title) }

        it { expect(response.body).not_to include(review.title) }
      end
    end

    describe 'GET show:' do
      before do
        get :show, params: { reviewable_type: reviewable.class.to_s, reviewable_id: reviewable.id, id: review.id },
                   format: :json
      end

      context 'when given review author and session as reviewable' do
        let(:current_user) { review.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given review author and recording as reviewable' do
        let(:review) { create(:recording_review_with_mandatory_rates) }
        let(:current_user) { review.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'POST create:' do
      let(:current_user) { session_participation.participant.user }
      let(:reviewable) { session_participation.session }
      let(:session_participation) do
        session_participation = create(:session_participation)
        session = session_participation.session
        session.start_at = Time.zone.now.beginning_of_hour - 1.day - Session.where("now() > (start_at + (INTERVAL '1 minute' * duration))").count.days
        def session.not_in_the_past
          # skip it
        end
        session.save!
        session_participation
      end
      let(:params) do
        {
          reviewable_type: reviewable.class.to_s,
          reviewable_id: reviewable.id,
          title: Forgery(:lorem_ipsum).words(3, random: true),
          overall_experience_comment: Forgery(:lorem_ipsum).words(10, random: true),
          technical_experience_comment: Forgery(:lorem_ipsum).words(10, random: true),
          quality_of_content: (1..5).to_a.sample,
          sound_quality: (1..5).to_a.sample,
          video_quality: (1..5).to_a.sample
        }
      end

      before { post :create, params: params, format: :json }

      context 'when given session as reviewable' do
        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given recording as reviewable' do
        let(:current_user) { recording_member.participant.user }
        let(:reviewable) { recording_member.recording }
        let(:recording_member) { create(:recording_member, recording: create(:recording_published)) }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given rating only' do
        let(:params) do
          {
            reviewable_type: reviewable.class.to_s,
            reviewable_id: reviewable.id,
            quality_of_content: (1..5).to_a.sample,
            sound_quality: nil,
            video_quality: nil
          }
        end

        it { expect(response).to be_successful }
      end
    end

    describe 'PUT update:' do
      let(:params) do
        {
          id: review.id,
          reviewable_type: reviewable.class.to_s,
          reviewable_id: reviewable.id,
          title: Forgery(:lorem_ipsum).words(3, random: true),
          overall_experience_comment: Forgery(:lorem_ipsum).words(10, random: true),
          technical_experience_comment: Forgery(:lorem_ipsum).words(10, random: true),
          quality_of_content: (1..5).to_a.sample,
          sound_quality: (1..5).to_a.sample,
          video_quality: (1..5).to_a.sample
        }
      end

      before { put :update, params: params, format: :json }

      context 'when given review author and session as reviewable' do
        let(:current_user) { review.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given review author and recording as reviewable' do
        let(:review) { create(:recording_review_with_mandatory_rates) }
        let(:current_user) { review.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given reviewable owner' do
        let(:params) { { id: review.id, visible: false } }
        let(:review) { create(%i[session_review_with_mandatory_rates recording_review_with_mandatory_rates].sample) }
        let(:current_user) { review.commentable.organizer }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }

        it { expect(review.reload.visible).to be_falsey }
      end
    end

    describe 'DELETE destroy:' do
      let(:params) do
        {
          id: review.id,
          reviewable_type: reviewable.class.to_s,
          reviewable_id: reviewable.id
        }
      end

      before { delete :destroy, params: params, format: :json }

      context 'when given review author and session as reviewable' do
        let(:current_user) { review.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end

      context 'when given review author and recording as reviewable' do
        let(:review) { create(:recording_review_with_mandatory_rates) }
        let(:current_user) { review.user }

        it { expect(response).to be_successful }

        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end
  end
end
