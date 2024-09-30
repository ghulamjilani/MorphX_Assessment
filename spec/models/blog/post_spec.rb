# frozen_string_literal: true
require 'spec_helper'

describe Blog::Post do
  let(:blog_post) { create(:blog_post) }

  describe 'validations' do
    it 'checks presence of channel' do
      post = build(:blog_post, channel: nil, user: create(:user))
      post.valid?
      expect(post.errors[:channel_id]).not_to be_nil
    end

    it 'checks presence of user' do
      post = build(:blog_post, user: nil)
      post.valid?
      expect(post.errors[:user_id]).not_to be_nil
    end
  end

  describe 'scopes' do
    describe 'visible_for_user' do
      subject(:posts) { described_class.visible_for_user(user) }

      context 'when given no user' do
        let(:user) { nil }

        it { expect { posts }.not_to raise_error }
      end

      context 'when given a user' do
        let(:user) { create(:user) }

        it { expect { posts }.not_to raise_error }
      end
    end

    describe 'editable_by_user' do
      subject(:posts) { described_class.editable_by_user(user) }

      context 'when given no user' do
        let(:user) { nil }

        it { expect { posts }.not_to raise_error }
      end

      context 'when given a user' do
        let(:user) { create(:user) }

        it { expect { posts }.not_to raise_error }
      end
    end
  end

  Blog::Post::Statuses::ALL.each do |status|
    other_status = Blog::Post::Statuses::ALL.reject { |s| s == status }.sample

    describe "#status_#{status}?" do
      let(:blog_post) { build(:blog_post, status: status) }

      context "when #{status}" do
        it 'returns true' do
          expect(blog_post.send("status_#{status}?".to_sym)).to eq true
        end
      end

      context "when #{other_status}" do
        let(:post_with_other_status) { build(:blog_post, status: other_status) }

        it 'returns false' do
          expect(post_with_other_status.send("status_#{status}?".to_sym)).to eq false
        end
      end
    end

    describe "#status_#{status}!" do
      let(:post_with_other_status) { create(:blog_post, status: other_status) }

      it "updates status to '#{status}'" do
        expect do
          post_with_other_status.send("status_#{status}!".to_sym)
        end.to change(post_with_other_status,
                      :status).from(other_status).to(status)
      end
    end
  end

  describe '#is_fake?' do
    let(:channel_fake_organizer) do
      create(:listed_channel, fake: false, organization: create(:organization, user: create(:user, fake: true)))
    end
    let(:post_not_fake) { build(:blog_post) }
    let(:post_fake_channel) { build(:blog_post, channel: create(:listed_channel, fake: true)) }
    let(:post_fake_user) { build(:blog_post, channel: channel_fake_organizer) }

    context 'when fake' do
      it 'returns true' do
        expect(post_fake_channel).to be_is_fake
        expect(post_fake_user).to be_is_fake
      end
    end

    context 'when not fake' do
      it 'returns false' do
        expect(post_not_fake).not_to be_is_fake
      end
    end
  end

  describe '#share_image_url' do
    subject(:image) { blog_post.share_image_url }

    it { expect { image }.not_to raise_error }
  end

  describe '#share_description' do
    subject(:description) { blog_post.share_description }

    it { expect { description }.not_to raise_error }
    it { expect(description).to be_truthy }
  end

  describe '#share_title' do
    subject(:title) { blog_post.share_title }

    it { expect { title }.not_to raise_error }
    it { expect(title).to be_truthy }
  end

  describe '#notify_mentioned_users' do
    subject(:notify_mentioned_users) { blog_post.notify_mentioned_users }

    it { expect { notify_mentioned_users }.not_to raise_error }
  end

  describe '.visible_for_user for marketplace' do
    let(:user) { create(:user) }
    let(:blog_post_published) { create(:blog_post_published) }
    let(:blog_post_hidden) { create(:blog_post_hidden) }
    let(:blog_post) { blog_post_published }
    let(:channel) { blog_post.channel }

    context 'when no user given' do
      let(:user) { nil }

      context 'when given published post' do
        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
      end

      context 'when given hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).not_to exist }
      end
    end

    context 'when given random user' do
      context 'when given published post' do
        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
      end

      context 'when given hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).not_to exist }
      end
    end

    context 'when given service_admin user' do
      let(:user) { create(:user_service_admin) }

      context 'when given published post' do
        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
      end

      context 'when given hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
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
      let(:blog_post_published) { create(:blog_post_published, channel: channel) }
      let(:blog_post_hidden) { create(:blog_post_published, channel: channel) }

      context 'when group member is not assigned to any channel' do
        context 'when blog post is published' do
          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
        end

        context 'when blog post is hidden' do
          let(:blog_post) { blog_post_hidden }

          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
        end
      end

      context 'when group member assigned to specific channel' do
        let(:group_member_channel) do
          create(:access_management_groups_members_channel, groups_member: group_member, channel: channel)
        end
        let(:user) { group_member_channel.user }

        context 'when blog post is published' do
          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
        end

        context 'when blog post is hidden' do
          let(:blog_post) { blog_post_hidden }

          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
        end
      end
    end
  end

  describe '.visible_for_user for enterprise' do
    let(:user) { create(:user) }
    let(:blog_post_published) { create(:blog_post_published) }
    let(:blog_post_hidden) { create(:blog_post_hidden) }
    let(:blog_post) { blog_post_published }
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

      context 'when given published post' do
        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).not_to exist }
      end

      context 'when given hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).not_to exist }
      end
    end

    context 'when given random user' do
      context 'when given published post' do
        let(:blog_post_published) { create(:blog_post_published) }

        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).not_to exist }
      end

      context 'when given hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).not_to exist }
      end
    end

    context 'when given service_admin user' do
      let(:user) { create(:user_service_admin) }

      context 'when given published post' do
        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
      end

      context 'when given hidden post' do
        let(:blog_post) { blog_post_hidden }

        it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
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
      let(:blog_post_published) { create(:blog_post_published, channel: channel) }
      let(:blog_post_hidden) { create(:blog_post_hidden, channel: channel) }

      context 'when group member is not assigned to any channel' do
        context 'when blog post is published' do
          let!(:blog_post) { blog_post_published }

          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
        end

        context 'when blog post is hidden' do
          let!(:blog_post) { blog_post_hidden }

          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
        end
      end

      context 'when group member assigned to specific channel' do
        let(:group_member_channel) do
          create(:access_management_groups_members_channel, groups_member: group_member, channel: channel)
        end
        let(:user) { group_member_channel.user }

        context 'when blog post is published' do
          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
        end

        context 'when blog post is hidden' do
          let(:blog_post) { blog_post_hidden }

          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
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
          let!(:blog_post) { blog_post_published }

          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
        end

        context 'when blog post is hidden' do
          let!(:blog_post) { blog_post_hidden }

          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).not_to exist }
        end
      end

      context 'when group member assigned to specific channel' do
        let(:group_member_channel) do
          create(:access_management_groups_members_channel, groups_member: group_member, channel: channel)
        end
        let(:user) { group_member_channel.user }

        context 'when blog post is published' do
          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).to exist }
        end

        context 'when blog post is hidden' do
          let(:blog_post) { blog_post_hidden }

          it { expect(::Blog::Post.visible_for_user(user).where(id: blog_post.id)).not_to exist }
        end
      end
    end
  end

  describe '#update_published_at' do
    context 'when published_at empty' do
      let(:blog_post) { create(:blog_post_draft) }

      it { expect { blog_post.status_published! }.to change(blog_post, :published_at) }
    end

    context 'when published_at present' do
      let(:blog_post) { create(:blog_post_draft, published_at: Time.now) }

      it { expect { blog_post.status_published! }.not_to change(blog_post, :published_at) }
    end
  end
end
