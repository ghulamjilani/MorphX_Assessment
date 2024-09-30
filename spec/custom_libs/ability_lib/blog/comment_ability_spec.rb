# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::Blog::CommentAbility do
  let(:subject) { described_class.new(current_user) }
  let(:blog_comment) { create(:blog_comment) }

  describe '#read, #comment' do
    context 'when given comment on published post' do
      context 'when given random user' do
        let(:current_user) { create(:user) }

        it { is_expected.to be_able_to :read, blog_comment }

        it { is_expected.to be_able_to :comment, blog_comment }
      end
    end

    context 'when given comment on hidden post' do
      let(:blog_post) { create(:blog_post_hidden) }
      let(:blog_comment) { create(:blog_comment, commentable: blog_post) }

      context 'when given organization owner' do
        let(:current_user) { blog_comment.post.organization.user }

        it { is_expected.to be_able_to :read, blog_comment }

        it { is_expected.to be_able_to :comment, blog_comment }
      end

      context 'when given comment author' do
        let(:current_user) { blog_comment.author }

        it { is_expected.to be_able_to :read, blog_comment }

        it { is_expected.to be_able_to :comment, blog_comment }
      end

      context 'when given organization member with proper credential' do
        let(:blog_post) { create(:blog_post_hidden) }
        let(:current_user) { create(:user) }

        before do
          allow(current_user).to receive(:has_channel_credential?).with(blog_comment.post.channel,
                                                                        %i[manage_blog_post
                                                                           moderate_blog_post]).and_return(true)
        end

        it { is_expected.to be_able_to :read, blog_comment }

        it { is_expected.to be_able_to :comment, blog_comment }
      end

      context 'when given service_admin user' do
        let(:current_user) { create(:user_service_admin) }

        it { is_expected.to be_able_to :read, blog_comment }

        it { is_expected.to be_able_to :comment, blog_comment }
      end

      context 'when given random user' do
        let(:current_user) { create(:user) }

        it { is_expected.not_to be_able_to :read, blog_comment }

        it { is_expected.not_to be_able_to :comment, blog_comment }
      end
    end
  end

  describe '#edit' do
    context 'when given comment author' do
      let(:current_user) { blog_comment.author }

      it { is_expected.to be_able_to :edit, blog_comment }
    end

    context 'when given random user' do
      let(:current_user) { create(:user) }

      it { is_expected.not_to be_able_to :edit, blog_comment }
    end
  end

  describe '#destroy' do
    context 'when given comment author' do
      let(:current_user) { blog_comment.author }

      it { is_expected.to be_able_to :destroy, blog_comment }
    end

    context 'when given comment post author' do
      let(:current_user) { blog_comment.post.author }

      it { is_expected.to be_able_to :destroy, blog_comment }
    end

    context 'when given post organization member with proper credential' do
      let(:current_user) { create(:user) }

      before do
        allow(current_user).to receive(:has_channel_credential?).with(blog_comment.post.channel,
                                                                      %i[manage_blog_post
                                                                         moderate_blog_post]).and_return(true)
      end

      it { is_expected.to be_able_to :destroy, blog_comment }
    end

    context 'when given random user' do
      let(:current_user) { create(:user) }

      it { is_expected.not_to be_able_to :destroy, blog_comment }
    end
  end
end
