# frozen_string_literal: true

require 'spec_helper'

describe BlogMailer do
  let(:user) { create(:user) }
  let(:comment) { create(:blog_comment) }
  let(:blog_post) { comment.post }

  describe '#new_mention_in_post' do
    it 'does not fail' do
      expect { described_class.new_mention_in_post(blog_post.id, user.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.new_mention_in_post(blog_post.id, user.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#new_mention_in_comment' do
    it 'does not fail' do
      expect { described_class.new_mention_in_comment(comment.id, user.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.new_mention_in_comment(comment.id, user.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end
end
