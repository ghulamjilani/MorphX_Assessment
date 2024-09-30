# frozen_string_literal: true

require 'spec_helper'

describe HomePageStore do
  describe '#recordings' do
    it 'works' do
      create(:recording)

      obj = described_class.new(nil)
      expect { obj.recordings }.not_to raise_error
    end
  end

  describe '#replays' do
    it 'works' do
      create(:recorded_session)

      obj = described_class.new(nil)
      expect { obj.replays }.not_to raise_error
    end
  end

  describe '#channels' do
    it 'works' do
      create(:channel)

      obj = described_class.new(nil)
      expect { obj.channels }.not_to raise_error
    end
  end

  describe '#creators' do
    it 'works' do
      create(:presenter_with_presenter_account)

      obj = described_class.new(nil)
      expect { obj.creators }.not_to raise_error
    end
  end

  describe '#live_now' do
    it 'works' do
      create(:published_session)

      obj = described_class.new(nil)
      expect { obj.live_now }.not_to raise_error
    end
  end

  describe '#upcoming' do
    it 'works' do
      create(:published_session)

      obj = described_class.new(nil)
      expect { obj.upcoming }.not_to raise_error
    end
  end
end
