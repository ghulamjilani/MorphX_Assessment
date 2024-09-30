# frozen_string_literal: true
require 'spec_helper'

describe Blog::Comment do
  let(:blog_comment) { create(:blog_comment) }

  describe 'validations' do
    it 'validates presence of commentable' do
      comment = build(:blog_comment, commentable: nil)
      comment.valid?
      expect(comment.errors[:commentable]).not_to be_nil
    end

    it 'validates presence of user' do
      comment = build(:blog_comment, user: nil)
      comment.valid?
      expect(comment.errors[:user]).not_to be_nil
    end

    it 'validates presence of body' do
      comment = build(:blog_comment, body: '')
      comment.valid?
      expect(comment.errors[:body]).not_to be_nil
    end
  end

  describe '#notify_mentioned_users' do
    subject(:notify_mentioned_users) { blog_comment.notify_mentioned_users }

    it { expect { notify_mentioned_users }.not_to raise_error }
  end

  describe '.visible_for_user for marketplace' do
    let(:user) { create(:user) }
    let(:blog_post_published) { create(:blog_post_published) }
    let(:blog_post_hidden) { create(:blog_post_hidden) }
    let(:blog_post) { blog_post_published }
    let!(:blog_comment) { create(:blog_comment, commentable: blog_post) }
    let(:channel) { blog_post.channel }

    context 'when no user given' do
      let(:user) { nil }

      context 'when given comment on published post' do
        let(:blog_post_published) { create(:blog_post_published) }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
      end

      context 'when given comment on hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).not_to exist }
      end
    end

    context 'when given random user' do
      context 'when given comment on published post' do
        let(:blog_post_published) { create(:blog_post_published) }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
      end

      context 'when given comment on hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).not_to exist }
      end
    end

    context 'when given service_admin user' do
      let(:user) { create(:user_service_admin) }

      context 'when given comment on published post' do
        let(:blog_post_published) { create(:blog_post_published) }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
      end

      context 'when given comment on hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
      end
    end

    context 'when given user with manage blog post credentials' do
      let(:access_management_credential) do
        create(:access_management_credential, code: ::AccessManagement::Credential::Codes::MANAGE_BLOG_POST,
                                              is_for_channel: true)
      end
      let(:group_credential) do
        create(:access_management_organizational_groups_credential, credential: access_management_credential)
      end
      let(:group) { group_credential.group }
      let(:organization) { group.organization }
      let(:group_member) do
        create(:access_management_groups_member, group: group,
                                                 organization_membership: create(:organization_membership, organization: organization))
      end
      let(:user) { group_member.user }
      let(:channel) { create(:listed_channel, organization: organization) }
      let(:blog_post_published) { create(:blog_post_published, channel: channel) }
      let(:blog_post_hidden) { create(:blog_post_published, channel: channel) }

      context 'when group member is not assigned to any channel' do
        context 'when blog post is published' do
          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
        end

        context 'when blog post is hidden' do
          let(:blog_post) { blog_post_hidden }

          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
        end
      end

      context 'when group member assigned to specific channel' do
        let(:group_member_channel) do
          create(:access_management_groups_members_channel, groups_member: group_member, channel: channel)
        end
        let(:user) { group_member_channel.user }

        context 'when blog post is published' do
          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
        end

        context 'when blog post is hidden' do
          let(:blog_post) { blog_post_hidden }

          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
        end
      end
    end
  end

  describe '.visible_for_user for enterprise' do
    let(:user) { create(:user) }
    let(:blog_post_published) { create(:blog_post_published) }
    let(:blog_post_hidden) { create(:blog_post_hidden) }
    let(:blog_post) { blog_post_published }
    let!(:blog_comment) { create(:blog_comment, commentable: blog_post) }
    let(:channel) { blog_post.channel }
    let(:global_credentials) do
      global_credentials = JSON.parse(Rails.application.credentials.global.to_json).deep_symbolize_keys
      global_credentials[:enterprise] = true
      global_credentials
    end

    before do
      allow(Rails.application.credentials).to receive(:global).and_return(global_credentials)
    end

    context 'when no user given' do
      let(:user) { nil }

      context 'when given comment on published post' do
        let(:blog_post_published) { create(:blog_post_published) }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).not_to exist }
      end

      context 'when given comment on hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).not_to exist }
      end
    end

    context 'when given random user' do
      context 'when given comment on published post' do
        let(:blog_post_published) { create(:blog_post_published) }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).not_to exist }
      end

      context 'when given comment on hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).not_to exist }
      end
    end

    context 'when given service_admin user' do
      let(:user) { create(:user_service_admin) }

      context 'when given comment on published post' do
        let(:blog_post_published) { create(:blog_post_published) }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
      end

      context 'when given comment on hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
      end
    end

    context 'when given user with manage_blog_post credentials' do
      let(:access_management_credential) do
        create(:access_management_credential, code: ::AccessManagement::Credential::Codes::MANAGE_BLOG_POST,
                                              is_for_channel: true)
      end
      let(:group_credential) do
        create(:access_management_organizational_groups_credential, credential: access_management_credential)
      end
      let(:group) { group_credential.group }
      let(:organization) { group.organization }
      let(:group_member) do
        create(:access_management_groups_member, group: group,
                                                 organization_membership: create(:organization_membership, organization: organization))
      end
      let(:user) { group_member.user }
      let(:channel) { create(:listed_channel, organization: organization) }
      let(:blog_post_hidden) { create(:blog_post_hidden, channel: channel) }
      let(:blog_post_published) { create(:blog_post_published, channel: channel) }

      context 'when group member is not assigned to any channel' do
        context 'when blog post is published' do
          let(:blog_post) { create(:blog_post_published, channel: channel) }
          let!(:blog_comment) { create(:blog_comment, commentable: blog_post) }

          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
        end

        context 'when blog post is hidden' do
          let!(:blog_comment) { create(:blog_comment, commentable: blog_post_hidden) }

          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
        end
      end

      context 'when group member assigned to specific channel' do
        let(:group_member_channel) do
          create(:access_management_groups_members_channel, groups_member: group_member, channel: channel)
        end
        let(:user) { group_member_channel.user }

        context 'when blog post is published' do
          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
        end

        context 'when blog post is hidden' do
          let(:blog_post) { blog_post_hidden }

          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
        end
      end
    end

    context 'when given user with view_content credentials' do
      let(:access_management_credential) do
        create(:access_management_credential, code: ::AccessManagement::Credential::Codes::VIEW_CONTENT,
                                              is_for_channel: true)
      end
      let(:group_credential) do
        create(:access_management_organizational_groups_credential, credential: access_management_credential)
      end
      let(:group) { group_credential.group }
      let(:organization) { group.organization }
      let(:group_member) do
        create(:access_management_groups_member, group: group,
                                                 organization_membership: create(:organization_membership, organization: organization))
      end
      let(:user) { group_member.user }
      let(:channel) { create(:listed_channel, organization: organization) }
      let(:blog_post_published) { create(:blog_post_published, channel: channel) }
      let(:blog_post_hidden) { create(:blog_post_hidden, channel: channel) }

      context 'when group member is not assigned to any channel' do
        context 'when blog post is published' do
          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
        end

        context 'when blog post is hidden' do
          let!(:blog_comment) { create(:blog_comment, commentable: blog_post_hidden) }

          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).not_to exist }
        end
      end

      context 'when group member assigned to specific channel' do
        let(:group_member_channel) do
          create(:access_management_groups_members_channel, groups_member: group_member, channel: channel)
        end
        let(:user) { group_member_channel.user }

        context 'when blog post is published' do
          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).to exist }
        end

        context 'when blog post is hidden' do
          let(:blog_post) { blog_post_hidden }

          it { expect(::Blog::Comment.visible_for_user(user).where(id: blog_comment.id)).not_to exist }
        end
      end
    end
  end
end
