# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe UserJobs::AddContactUsersJob do
  let(:contact) { create(:contact) }
  let(:user) { contact.for_user }
  let(:emails) { (0..3).map { create(:user).email } }

  it { expect { Sidekiq::Testing.inline! { described_class.perform_async(user.id, emails) } }.not_to raise_error }

  it { expect { described_class.new.perform(user.id, emails) }.to change(user.contacts, :count).by(emails.count) }

  it { expect { described_class.new.perform(user.id, [contact.email]) }.not_to change(user.contacts, :count) }
end
