# frozen_string_literal: true
require 'spec_helper'

describe View do
  let(:view) { build(:guest_user_view) }

  describe 'validations' do
    describe 'user_id or ip_address presence validation' do
      it { expect(view).to be_valid }

      context 'when user_id and ip_address are blank' do
        let(:view) { build(:guest_user_view, ip_address: nil, user_id: nil) }

        it { expect(view).not_to be_valid }
      end
    end

    it 'sets group_name' do
      view.valid?
      expect(view.group_name).to be_present
    end
  end

  describe '#user_id_or_ip' do
    context 'when user_id present' do
      let(:view) { build(:guest_user_view, user: create(:user)) }

      it { expect { view.user_id_or_ip }.not_to raise_error }

      it { expect(view.user_id_or_ip).to be_present }
    end

    context 'when user_id blank' do
      let(:view) { build(:guest_user_view, user_id: nil) }

      it { expect { view.user_id_or_ip }.not_to raise_error }

      it { expect(view.user_id_or_ip).to be_present }
    end
  end

  describe 'private methods' do
    describe '#set_group_name' do
      it { expect { view.send(:set_group_name) }.not_to raise_error }

      it { expect { view.send(:set_group_name) }.to change(view, :group_name) }
    end
  end
end
