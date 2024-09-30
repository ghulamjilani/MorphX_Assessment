# frozen_string_literal: true
require 'spec_helper'

describe SignupToken do
  let(:signup_token) { create(:signup_token) }
  let(:signup_token_expired) do
    model = create(:signup_token)
    model.update_column(:created_at, (described_class.lifetime_days + 1).days.ago)
    model
  end
  let(:signup_token_used) { create(:signup_token, user: create(:user)) }

  describe '.scopes' do
    describe '.used' do
      subject(:tested_scope) { described_class.used }

      it { expect { tested_scope }.not_to raise_error }
    end

    describe '.not_used' do
      subject(:tested_scope) { described_class.not_used }

      it { expect { tested_scope }.not_to raise_error }
    end

    describe '.not_expired' do
      subject(:tested_scope) { described_class.not_expired }

      it { expect { tested_scope }.not_to raise_error }
    end
  end

  describe 'Class methods' do
    describe '.lifetime_days' do
      it { expect { described_class.lifetime_days }.not_to raise_error }
    end
  end

  describe 'Instance methods' do
    describe '#expired?' do
      it { expect { signup_token.expired? }.not_to raise_error }

      it { expect(signup_token).not_to be_expired }

      it { expect(signup_token_expired).to be_expired }
    end

    describe '#used?' do
      it { expect { signup_token.used? }.not_to raise_error }

      it { expect(signup_token).not_to be_used }

      it { expect(signup_token_used).to be_used }
    end

    describe '#usable?' do
      it { expect { signup_token.usable? }.not_to raise_error }

      it { expect(signup_token).to be_usable }

      it { expect(signup_token_used).not_to be_usable }

      it { expect(signup_token_expired).not_to be_usable }
    end

    describe '#refresh_token' do
      it { expect { signup_token.refresh_token }.not_to raise_error }

      it { expect { signup_token.refresh_token }.to change(signup_token, :token) }
    end

    describe '#user_attributes' do
      it { expect { signup_token.user_attributes }.not_to raise_error }

      it { expect(signup_token.user_attributes).to be_present }
    end

    describe '#used_by' do
      let(:user) { create(:user) }

      context 'when calling on usable token' do
        it { expect { signup_token.used_by(user) }.not_to raise_error }

        it { expect(signup_token.used_by(user)).to be_truthy }

        it { expect { signup_token.used_by(user) }.to change(signup_token, :user_id).to(user.id).and change(user, :can_use_wizard).to(signup_token.can_use_wizard).and change(signup_token, :used_at).from(nil) }
      end

      context 'when calling on expired token' do
        it { expect { signup_token_expired.used_by(user) }.not_to raise_error }

        it { expect(signup_token_expired.used_by(user)).to be_falsey }

        it { expect { signup_token_expired.used_by(user) }.not_to change(signup_token, :user_id) }
      end

      context 'when calling on used token' do
        it { expect { signup_token_used.used_by(user) }.not_to raise_error }

        it { expect(signup_token_used.used_by(user)).to be_falsey }

        it { expect { signup_token_used.used_by(user) }.not_to change(signup_token, :user_id) }
      end
    end

    describe '#used_by!' do
      let(:user) { create(:user) }

      context 'when calling on usable token' do
        it { expect { signup_token.used_by!(user) }.not_to raise_error }

        it { expect(signup_token.used_by!(user)).to be_truthy }
      end

      context 'when calling on expired token' do
        it { expect { signup_token_expired.used_by!(user) }.to raise_error(ActiveRecord::RecordInvalid).and not_change(signup_token_expired, :user_id).and not_change(user, :can_use_wizard) }
      end

      context 'when calling on used token' do
        it { expect { signup_token_used.used_by!(user) }.to raise_error(ActiveRecord::RecordInvalid).and not_change(signup_token_used, :user_id).and not_change(user, :can_use_wizard) }
      end
    end
  end
end
