# frozen_string_literal: true
require 'spec_helper'

describe Discount do
  describe '#valid_for?' do
    let(:user) { create(:participant).user }

    context 'when invalid discount' do
      let(:immersive_session) { create(:immersive_session) }

      it 'invalid discount always return false' do
        discount = create(:invalid_discount)
        expect(discount.valid_for?(immersive_session, 'Immersive', user)).to eq(false)
      end

      it 'expired discount always return false' do
        discount = create(:expired_discount)
        expect(discount.valid_for?(immersive_session, 'Immersive', user)).to eq(false)
      end
    end

    context 'when target_type Channel' do
      context 'when any channel' do
        let(:discount) { create(:channel_discount) }
        let(:session) { create(:recorded_session, livestream_purchase_price: 14.99) }

        %w[Livestream Immersive Replay].each do |type|
          it "valid for #{type} purchase" do
            expect(discount.valid_for?(session, type, user)).to eq(true)
          end
        end
      end

      context 'when specific channel' do
        let(:session) { create(:recorded_session, livestream_purchase_price: 14.99) }
        let(:channel) { session.channel }
        let(:discount) { create(:channel_discount, target_ids: [channel.id]) }
        let(:another_session) { create(:recorded_session, livestream_purchase_price: 14.99) }

        %w[Livestream Immersive Replay].each do |type|
          it "current channel session valid for #{type} purchase" do
            expect(discount.valid_for?(session, type, user)).to eq(true)
          end
        end
        %w[Livestream Immersive Replay].each do |type|
          it "another channel session not valid for #{type} purchase" do
            expect(discount.valid_for?(another_session, type, user)).to eq(false)
          end
        end
      end
    end

    context 'when target_type Session' do
      context 'when any Session' do
        let(:discount) { create(:session_discount) }
        let(:session) { create(:recorded_session, livestream_purchase_price: 14.99) }

        %w[Livestream Immersive Replay].each do |type|
          it "valid for #{type} purchase" do
            expect(discount.valid_for?(session, type, user)).to eq(true)
          end
        end
      end

      context 'when specific Session' do
        let(:session) { create(:recorded_session, livestream_purchase_price: 14.99) }
        let(:discount) { create(:session_discount, target_ids: [session.id]) }
        let(:another_session) { create(:recorded_session, livestream_purchase_price: 14.99) }

        %w[Livestream Immersive Replay].each do |type|
          it "current channel session valid for #{type} purchase" do
            expect(discount.valid_for?(session, type, user)).to eq(true)
          end
        end
        %w[Livestream Immersive Replay].each do |type|
          it "another session not valid for #{type} purchase" do
            expect(discount.valid_for?(another_session, type, user)).to eq(false)
          end
        end
      end
    end

    context 'when target_type Livestream' do
      context 'when any Session' do
        let(:discount) { create(:livestream_discount) }
        let(:session) { create(:livestream_session) }

        it 'valid for Livestream purchase' do
          expect(discount.valid_for?(session, 'Livestream', user)).to eq(true)
        end

        %w[Immersive Replay].each do |type|
          it "not valid for #{type} purchase" do
            expect(discount.valid_for?(session, type, user)).to eq(false)
          end
        end
      end

      context 'when specific Session' do
        let(:session) { create(:livestream_session) }
        let(:discount) { create(:livestream_discount, target_ids: [session.id]) }
        let(:another_session) { create(:livestream_session) }

        it 'valid for Livestream purchase' do
          expect(discount.valid_for?(session, 'Livestream', user)).to eq(true)
        end

        it 'another session not valid for Livestream purchase' do
          expect(discount.valid_for?(another_session, 'Livestream', user)).to eq(false)
        end
      end
    end

    context 'when target_type Immersive' do
      context 'when any Session' do
        let(:discount) { create(:immersive_discount) }
        let(:session) { create(:immersive_session) }

        it 'valid for Immersive purchase' do
          expect(discount.valid_for?(session, 'Immersive', user)).to eq(true)
        end

        %w[Livestream Replay].each do |type|
          it "not valid for #{type} purchase" do
            expect(discount.valid_for?(session, type, user)).to eq(false)
          end
        end
      end

      context 'when specific Session' do
        let(:session) { create(:immersive_session) }
        let(:discount) { create(:immersive_discount, target_ids: [session.id]) }
        let(:another_session) { create(:immersive_session) }

        it 'valid for Immersive purchase' do
          expect(discount.valid_for?(session, 'Immersive', user)).to eq(true)
        end

        it 'another session not valid for Immersive purchase' do
          expect(discount.valid_for?(another_session, 'Immersive', user)).to eq(false)
        end
      end
    end

    context 'when target_type Replay' do
      context 'when any Session' do
        let(:discount) { create(:replay_discount) }
        let(:session) { create(:recorded_session) }

        it 'valid for Replay purchase' do
          expect(discount.valid_for?(session, 'Replay', user)).to eq(true)
        end

        %w[Livestream Immersive].each do |type|
          it "not valid for #{type} purchase" do
            expect(discount.valid_for?(session, type, user)).to eq(false)
          end
        end
      end

      context 'when specific Session' do
        let(:session) { create(:recorded_session) }
        let(:discount) { create(:replay_discount, target_ids: [session.id]) }
        let(:another_session) { create(:recorded_session) }

        it 'valid for Replay purchase' do
          expect(discount.valid_for?(session, 'Replay', user)).to eq(true)
        end

        it 'another session not valid for Replay purchase' do
          expect(discount.valid_for?(another_session, 'Replay', user)).to eq(false)
        end
      end
    end
  end
end
