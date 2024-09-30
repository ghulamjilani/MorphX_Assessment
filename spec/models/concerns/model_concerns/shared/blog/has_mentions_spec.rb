# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Shared::Blog::HasMentions do
  let(:user) { create(:user) }

  describe '#mentioned_user_ids' do
    subject(:ids) { model.mentioned_user_ids }

    let(:body) { "<span class=\"mention\" data-id=\"#{user.id}\">@VasyaPupkin</span>" }

    context 'when called on blog post' do
      let(:model) { create(:blog_post, body: body) }

      it { expect { ids }.not_to raise_error }
      it { expect(ids).to include(user.id) }
    end

    context 'when called on blog comment' do
      let(:model) { create(:blog_comment, body: body) }

      it { expect { ids }.not_to raise_error }
      it { expect(ids).to include(user.id) }
    end
  end
end
