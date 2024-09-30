# frozen_string_literal: true

require 'spec_helper'

describe Html::Parser do
  describe '#mentioned_user_ids' do
    let(:user) { create(:user) }
    let(:body) { "<span class=\"mention\" data-id=\"#{user.id}\">@VasyaPupkin</span>" }

    it { expect { described_class.new(body).mentioned_user_ids }.not_to raise_error }
    it { expect(described_class.new(body).mentioned_user_ids).to include(user.id) }
  end
end
