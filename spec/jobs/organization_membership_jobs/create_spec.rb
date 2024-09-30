# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe OrganizationMembershipJobs::Create do
  let(:organization) { create(:organization) }
  let(:channel) { create(:channel, organization: organization) }
  let(:member_group) { create(:access_management_group, code: :member) }

  it 'creates org membership' do
    expect do
      Sidekiq::Testing.inline! { described_class.perform_async(first_name: Forgery('name').first_name, last_name: Forgery('name').last_name, email: Forgery('internet').email_address, gender: 'M', birthday: '11/11/2000', group_ids: [{ group_id: member_group.id, channel_ids: [channel.id] }], organization_id: organization.id, user_id: organization.user.id) }
    end.to change(OrganizationMembership, :count).by(1)
  end
end
