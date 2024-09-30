# frozen_string_literal: true
require 'spec_helper'

describe WishlistItem do
  let(:model) { create(:immersive_session) }
  let(:user) { model.channel.organizer }

  it 'does not allow multiple items per user per session' do
    create(:wishlist_item, user: user, model: model)

    expect do
      create(:wishlist_item, user: user, model: model)
    end.to raise_error(/has already been taken/)
  end
end
