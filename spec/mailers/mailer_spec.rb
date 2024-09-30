# frozen_string_literal: true

require 'spec_helper'

describe Mailer do
  let(:email) { Forgery(:internet).email_address }
  let(:room_member) { create(:room_member) }
  let(:room_member_banned) { create(:room_member_banned) }

  describe '#share_model_via_email' do
    context 'when model is a channel' do
      let(:model) { create(:channel) }

      it 'does not fail' do
        expect { described_class.share_model_via_email(email, model).deliver }.not_to raise_error
      end

      it 'sends email' do
        expect do
          described_class.share_model_via_email(email, model).deliver
        end.to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'when model is a session' do
      let(:model) { create(:session) }

      it 'does not fail' do
        expect { described_class.share_model_via_email(email, model).deliver }.not_to raise_error
      end

      it 'sends email' do
        expect do
          described_class.share_model_via_email(email, model).deliver
        end.to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'when model is a user' do
      let(:model) { create(:user) }

      it 'does not fail' do
        expect { described_class.share_model_via_email(email, model).deliver }.not_to raise_error
      end

      it 'sends email' do
        expect do
          described_class.share_model_via_email(email, model).deliver
        end.to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'when model is a recording' do
      let(:model) { create(:recording) }

      it 'does not fail' do
        expect { described_class.share_model_via_email(email, model).deliver }.not_to raise_error
      end

      it 'sends email' do
        expect do
          described_class.share_model_via_email(email, model).deliver
        end.to change(ActionMailer::Base.deliveries, :count)
      end
    end

    context 'when model is a video' do
      let(:model) { create(:video) }

      it 'does not fail' do
        expect { described_class.share_model_via_email(email, model).deliver }.not_to raise_error
      end

      it 'sends email' do
        expect do
          described_class.share_model_via_email(email, model).deliver
        end.to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end

  describe '#ban_user' do
    it 'does not fail' do
      expect { described_class.ban_user(room_member_banned.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect do
        described_class.ban_user(room_member_banned.id).deliver
      end.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  describe '#unban_user' do
    it 'does not fail' do
      expect { described_class.unban_user(room_member.id).deliver }.not_to raise_error
    end

    it 'sends email' do
      expect { described_class.unban_user(room_member.id).deliver }.to change(ActionMailer::Base.deliveries, :count)
    end
  end
end
