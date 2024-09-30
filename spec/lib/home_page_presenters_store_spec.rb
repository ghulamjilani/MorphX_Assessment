# frozen_string_literal: true

require 'spec_helper'

describe HomePagePresentersStore do
  describe 'when works' do
    let(:user1) { User.new(id: 1) }
    let(:user2) { User.new(id: 2) }
    let(:user3) { User.new(id: 3) }
    let(:user4) { User.new(id: 4) }
    let(:user5) { User.new(id: 5) }
    let(:user6) { User.new(id: 6) }
    let(:user7) { User.new(id: 7) }
    let(:user777) { User.new(id: 777) }
    let(:user888) { User.new(id: 888) }

    let :store do
      store = described_class.new
      store.raw_featured = [user1, user2, user3, user4, user5, user6, user7]
      store.raw_on_demand = [user1, user2, user3, user777, user888]
      store
    end

    it { expect(store.featured).to eq([user4, user5, user6, user7, user1, user2]) }
    it { expect(store.on_demand).to eq([user777, user888, user3]) }
  end

  describe 'when does not fail' do
    let :store do
      presenter1 = create(:presenter_with_presenter_account)
      create(:approved_channel, presenter: presenter1)
      create(:approved_channel, presenter: presenter1)

      described_class.new
    end

    it { expect { store.featured }.not_to raise_error }
    it { expect { store.brand_new }.not_to raise_error }
  end
end
