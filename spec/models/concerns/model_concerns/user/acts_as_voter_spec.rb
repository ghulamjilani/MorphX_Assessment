# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::User::ActsAsVoter do
  let(:voter) { create(:user) }
  let(:likeable) { create(:user) }

  describe '#liked?' do
    context 'when has not voted' do
      it { expect { voter.liked?(likeable) }.not_to raise_error }

      it { expect(voter).not_to be_liked(likeable) }
    end

    context 'when voted' do
      before do
        voter.vote_up_for(likeable)
      end

      it { expect { voter.liked?(likeable) }.not_to raise_error }

      it { expect(voter).to be_liked(likeable) }
    end
  end

  describe '#like' do
    it 'changes likes count' do
      expect { voter.like(likeable) }.to not_raise_error.and change(ActsAsVotable::Vote, :count)
    end
  end

  describe '#unlike' do
    before do
      voter.like(likeable)
    end

    it 'changes likes count' do
      expect { voter.unlike(likeable) }.to not_raise_error.and change(ActsAsVotable::Vote, :count)
    end
  end

  describe '#clear_liked_cache' do
    it { expect { voter.clear_liked_cache(likeable) }.not_to raise_error }
  end

  describe '#voted_model_cache_key' do
    it { expect { voter.voted_model_cache_key(likeable) }.to not_raise_error }

    it { expect(voter.voted_model_cache_key(likeable)).to be_present }
  end
end
