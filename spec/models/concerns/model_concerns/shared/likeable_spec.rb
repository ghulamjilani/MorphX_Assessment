# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Shared::Likeable do
  let(:user) { create(:user) }
  let(:likeable) { create(:user) }

  describe '#likes_count' do
    before do
      user.vote_up_for(likeable)
    end

    it { expect { likeable.likes_count }.not_to raise_error }

    it { expect(likeable.likes_count).to be_positive }
  end
end
