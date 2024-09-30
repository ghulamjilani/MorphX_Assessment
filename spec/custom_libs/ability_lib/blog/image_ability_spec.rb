# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::Blog::ImageAbility do
  let(:subject) { described_class.new(current_user) }

  describe '#update, #destroy' do
    context 'when given attached image' do
      let(:blog_image) { create(:blog_image_attached) }

      context 'when given random user' do
        let(:current_user) { create(:user) }

        it { is_expected.not_to be_able_to :update, blog_image }

        it { is_expected.not_to be_able_to :destroy, blog_image }
      end

      context 'when given organization owner' do
        let(:current_user) { blog_image.organization.user }

        it { is_expected.to be_able_to :update, blog_image }

        it { is_expected.to be_able_to :destroy, blog_image }
      end

      context 'when given post author' do
        let(:current_user) { blog_image.blog_post.author }

        it { is_expected.to be_able_to :update, blog_image }

        it { is_expected.to be_able_to :destroy, blog_image }
      end

      context 'when given user with proper credentials' do
        let(:member) { create(:organization_membership_administrator, organization_id: blog_image.organization_id) }
        let(:current_user) { member.user }
        let(:role) { create(:access_management_group) }

        before do
          create(:access_management_groups_credential,
                 credential: create(:access_management_credential, code: :manage_blog_post), group: role)
          create(:access_management_groups_member, organization_membership: member, group: role)
        end

        it { is_expected.to be_able_to :update, blog_image }

        it { is_expected.to be_able_to :destroy, blog_image }
      end
    end

    context 'when given image not attached to post' do
      let(:blog_image) { create(:blog_image_attached) }

      context 'when given user with proper credentials' do
        let(:member) { create(:organization_membership_administrator, organization_id: blog_image.organization_id) }
        let(:current_user) { member.user }
        let(:role) { create(:access_management_group) }

        before do
          create(:access_management_groups_credential,
                 credential: create(:access_management_credential, code: :manage_blog_post), group: role)
          create(:access_management_groups_member, organization_membership: member, group: role)
        end

        it { is_expected.to be_able_to :update, blog_image }

        it { is_expected.to be_able_to :destroy, blog_image }
      end
    end
  end
end
