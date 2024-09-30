# frozen_string_literal: true
require 'spec_helper'

describe Blog::PostCover do
  describe 'validations' do
    it 'checks presence of post_id' do
      post_cover = build(:blog_post_cover, post: nil)
      post_cover.valid?
      expect(post_cover.errors[:post_id]).not_to be_nil
    end
  end
end
