# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Public::ReviewsController do
  let(:review) { create(:session_review_with_mandatory_rates, title: SecureRandom.alphanumeric(40)) }
  let(:reviewable) { review.commentable }

  render_views

  describe '.json request format' do
    describe 'GET index:' do
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
      end

      context 'when review is from participant and visible' do
        it { expect(response.body).to include(review.title) }
      end

      context 'when review is from participant and hidden' do
        let(:review) do
          create(:session_review_with_mandatory_rates, visible: false, title: SecureRandom.alphanumeric(40))
        end

        it { expect(response.body).not_to include(review.title) }
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
    end
  end
end
