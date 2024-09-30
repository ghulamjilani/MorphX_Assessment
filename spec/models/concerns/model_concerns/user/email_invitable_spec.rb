# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::User::EmailInvitable do
  describe '.find_or_invite_by_email' do
    context 'when given user that invites' do
      subject(:tested_method) { User.find_or_invite_by_email(email, current_user) }

      let(:current_user) { create(:user) }

      context 'when given valid email' do
        let(:email) { Forgery(:internet).email_address }

        it { expect { tested_method }.not_to raise_error }
        it { expect(tested_method).to be_truthy }
      end

      context 'when given invalid email' do
        let(:email) { Forgery(:lorem_ipsum).words(1, random: true) }

        it { expect { tested_method }.not_to raise_error }
        it { expect(tested_method).to be_falsey }
      end
    end

    context 'when given no user that invites' do
      subject(:tested_method) { User.find_or_invite_by_email(email) }

      context 'when given valid email' do
        let(:email) { Forgery(:internet).email_address }

        it { expect { tested_method }.not_to raise_error }
        it { expect(tested_method).to be_truthy }
      end

      context 'when given invalid email' do
        let(:email) { Forgery(:lorem_ipsum).words(1, random: true) }

        it { expect { tested_method }.not_to raise_error }
        it { expect(tested_method).to be_falsey }
      end
    end
  end
end
