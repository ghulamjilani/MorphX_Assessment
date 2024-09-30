# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Settings::Notification do
  let(:user) { create(:user) }

  context 'when given new user without any persisted adjusted settings(default settings)' do
    it 'does not have any persisted settings by default(@see `receives_notification?` method)' do
      expect(RailsSettings::ScopedSettings.all.where(thing: user)).to be_blank
    end

    it 'enables non-_via_sms notifications and disables *_via_sms' do
      notification = described_class.initialize_from_scoped_settings(user)

      expect(notification.system_updates_via_web).to eq('1')
      expect(notification.system_updates_via_email).to eq('1')

      expect(notification.system_updates_via_sms).to eq('0')
    end

    it 'saves first updates properly & can properly read it afterwards' do
      attrs = { system_updates_via_email: '1',
                system_updates_via_web: '0',
                system_updates_via_sms: '1' }

      described_class.new(attrs).save_for(user)
      expect(user.receives_notification?(:system_updates_via_email)).to be true
      expect(user.receives_notification?(:system_updates_via_web)).to be false
      expect(user.receives_notification?(:system_updates_via_sms)).to be true

      expect(user.receives_notification?(:exclusive_offers_via_sms)).to be false

      notification = described_class.initialize_from_scoped_settings(user)
      expect(notification.system_updates_via_email).to eq('1')
      expect(notification.system_updates_via_web).to eq('0')
      expect(notification.system_updates_via_sms).to eq('1')
    end
  end

  describe 'reminders' do
    let(:notification_attributes) do
      {
        'hrs_72_via_email' => '1',
        'hrs_72_via_web' => '1',
        'hrs_72_via_sms' => '1',
        hrs_24_via_email: '0',
        hrs_24_via_web: '0',
        hrs_24_via_sms: '0',
        hrs_6_via_email: '0',
        hrs_6_via_web: '0',
        hrs_6_via_sms: '0',
        hrs_1_via_email: '0',
        hrs_1_via_web: '0',
        hrs_1_via_sms: '0',
        mins_15_via_email: '1',
        mins_15_via_web: '1',
        mins_15_via_sms: '1'
      }
    end

    let(:user) { create(:user) }

    it 'does not have any persisted settings by default(@see `receives_notification?` method)' do
      expect(RailsSettings::ScopedSettings.all.where(thing: user)).to be_blank
    end

    it 'sets initial settings' do
      described_class.new(notification_attributes).save_for(user)
      expect(user.receives_reminder?(:hrs_72_via_email)).to be true
      expect(user.receives_reminder?(:hrs_72_via_web)).to be true
      expect(user.receives_reminder?(:hrs_72_via_sms)).to be true

      expect(user.receives_reminder?(:hrs_24_via_email)).to be false
      expect(user.receives_reminder?(:hrs_24_via_web)).to be false
      expect(user.receives_reminder?(:hrs_24_via_sms)).to be false

      expect(user.receives_reminder?(:hrs_6_via_email)).to be false
      expect(user.receives_reminder?(:hrs_6_via_web)).to be false
      expect(user.receives_reminder?(:hrs_6_via_sms)).to be false

      expect(user.receives_reminder?(:hrs_1_via_email)).to be false
      expect(user.receives_reminder?(:hrs_1_via_web)).to be false
      expect(user.receives_reminder?(:hrs_1_via_sms)).to be false

      expect(user.receives_reminder?(:mins_15_via_email)).to be true
      expect(user.receives_reminder?(:mins_15_via_web)).to be true
      expect(user.receives_reminder?(:mins_15_via_sms)).to be true
    end

    it 'updates settings' do
      described_class.new(notification_attributes).save_for(user)
      updated_attributes = {
        hrs_72_via_email: '1',
        hrs_72_via_web: '0',
        hrs_72_via_sms: '1'
      }
      described_class.new(updated_attributes).save_for(user)

      expect(user.receives_reminder?(:hrs_72_via_email)).to be true
      expect(user.receives_reminder?(:hrs_72_via_web)).to be false
      expect(user.receives_reminder?(:hrs_72_via_sms)).to be true
    end
  end
end
