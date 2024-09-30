# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Shared::Viewable do
  let(:view) { create(:view) }
  let(:viewable) { view.viewable }

  describe '#unique_view_exists?' do
    context 'when view exists' do
      it { expect(viewable).to be_unique_view_exists(view.user_id) }
    end

    context 'when view does not exist' do
      it { expect(viewable).not_to be_unique_view_exists(Forgery(:internet).ip_v4) }
    end
  end

  describe '#unique_view_group_start_at' do
    context 'when viewable is user' do
      it { expect { viewable.unique_view_group_start_at }.not_to raise_error }
    end

    context 'when viewable is session' do
      let(:viewable) { create(:session) }

      it { expect { viewable.unique_view_group_start_at }.not_to raise_error }
    end

    context 'when viewable is recording' do
      let(:viewable) { build(:recording) }

      it { expect { viewable.unique_view_group_start_at }.not_to raise_error }
    end

    context 'when viewable is video' do
      let(:viewable) { build(:video) }

      it { expect { viewable.unique_view_group_start_at }.not_to raise_error }
    end
  end

  describe '#unique_view_group_name' do
    it { expect { viewable.unique_view_group_name('127.0.0.1') }.not_to raise_error }
  end

  describe '#count_unique_views' do
    let(:view) { create(:user_view) }

    it { expect { viewable.count_unique_views }.not_to raise_error }

    it { expect(viewable.count_unique_views).to eq(1) }
  end
end
