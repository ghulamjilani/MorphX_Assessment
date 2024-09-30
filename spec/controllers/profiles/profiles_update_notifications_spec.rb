# frozen_string_literal: true

require 'spec_helper'

describe ProfilesController do
  let(:current_user) { create(:user) }
  let(:notifications_params_stub) do
    { notifications: { ModelConcerns::Settings::Notification::SYSTEM_UPDATES_VIA_EMAIL => '1',
                       ModelConcerns::Settings::Notification::SYSTEM_UPDATES_VIA_WEB => '1', ModelConcerns::Settings::Notification::SYSTEM_UPDATES_VIA_SMS => '1' } }
  end
  let(:combined_notifications_params_stub) do
    { combined_notification_settings: { '0' => {
      action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, frequency: '1,2,3', enabled: false
    } } }
  end

  before do
    sign_in current_user, scope: :user
  end

  describe 'PUT :profile' do
    describe 'notifications settings update' do
      it 'updates notification settings' do
        notifications = {
          ModelConcerns::Settings::Notification::SYSTEM_UPDATES_VIA_EMAIL => '1',
          ModelConcerns::Settings::Notification::SYSTEM_UPDATES_VIA_WEB => '1',
          ModelConcerns::Settings::Notification::SYSTEM_UPDATES_VIA_SMS => '1',
          ModelConcerns::Settings::Notification::SYSTEM_RECOMMENDS_CLASSES_VIA_EMAIL => '0',
          ModelConcerns::Settings::Notification::SYSTEM_RECOMMENDS_CLASSES_VIA_WEB => '0',
          ModelConcerns::Settings::Notification::SYSTEM_RECOMMENDS_CLASSES_VIA_SMS => '0',
          ModelConcerns::Settings::Notification::SYSTEM_ANNOUNCES_NEW_CLASSES_VIA_EMAIL => '1',
          ModelConcerns::Settings::Notification::SYSTEM_ANNOUNCES_NEW_CLASSES_VIA_WEB => '1',
          ModelConcerns::Settings::Notification::SYSTEM_ANNOUNCES_NEW_CLASSES_VIA_SMS => '1',
          ModelConcerns::Settings::Notification::NEWSLETTER_VIA_EMAIL => '0',
          ModelConcerns::Settings::Notification::NEWSLETTER_VIA_WEB => '0',
          ModelConcerns::Settings::Notification::NEWSLETTER_VIA_SMS => '0',
          ModelConcerns::Settings::Notification::EXCLUSIVE_OFFERS_VIA_EMAIL => '1',
          ModelConcerns::Settings::Notification::EXCLUSIVE_OFFERS_VIA_WEB => '1',
          ModelConcerns::Settings::Notification::EXCLUSIVE_OFFERS_VIA_SMS => '1',
          ModelConcerns::Settings::Notification::FOLLOW_ME_VIA_EMAIL => '0',
          ModelConcerns::Settings::Notification::FOLLOW_ME_VIA_WEB => '0',
          ModelConcerns::Settings::Notification::FOLLOW_ME_VIA_SMS => '0',
          ModelConcerns::Settings::Notification::PARTICIPANT_INVITED_TO_ABSTRACT_SESSION_VIA_EMAIL => '0',
          ModelConcerns::Settings::Notification::PARTICIPANT_INVITED_TO_ABSTRACT_SESSION_VIA_WEB => '0',
          ModelConcerns::Settings::Notification::PARTICIPANT_INVITED_TO_ABSTRACT_SESSION_VIA_SMS => '0',
          ModelConcerns::Settings::Notification::WISHLIST_SESSION_VIA_EMAIL => '1',
          ModelConcerns::Settings::Notification::WISHLIST_SESSION_VIA_WEB => '1',
          ModelConcerns::Settings::Notification::WISHLIST_SESSION_VIA_SMS => '1',

          ModelConcerns::Settings::Notification::HRS_72_VIA_EMAIL => 1,
          ModelConcerns::Settings::Notification::HRS_72_VIA_WEB => 1,
          ModelConcerns::Settings::Notification::HRS_72_VIA_SMS => 1,
          ModelConcerns::Settings::Notification::HRS_24_VIA_EMAIL => 0,
          ModelConcerns::Settings::Notification::HRS_24_VIA_WEB => 0,
          ModelConcerns::Settings::Notification::HRS_24_VIA_SMS => 0,
          ModelConcerns::Settings::Notification::HRS_6_VIA_EMAIL => 1,
          ModelConcerns::Settings::Notification::HRS_6_VIA_WEB => 1,
          ModelConcerns::Settings::Notification::HRS_6_VIA_SMS => 1,
          ModelConcerns::Settings::Notification::MINS_15_VIA_EMAIL => 0,
          ModelConcerns::Settings::Notification::MINS_15_VIA_WEB => 0,
          ModelConcerns::Settings::Notification::MINS_15_VIA_SMS => 0
        }
        # should work both in ways - 0 or skipped(unchecked checkbox)
        if rand(2).zero?
          notifications[ModelConcerns::Settings::Notification::PARTICIPANT_INVITED_TO_ABSTRACT_SESSION_VIA_EMAIL] = 0
          notifications[ModelConcerns::Settings::Notification::PARTICIPANT_INVITED_TO_ABSTRACT_SESSION_VIA_WEB] = 0
          notifications[ModelConcerns::Settings::Notification::PARTICIPANT_INVITED_TO_ABSTRACT_SESSION_VIA_SMS] = 0
        end

        params = { notifications: notifications }.merge(combined_notifications_params_stub)
        put :update, params: params

        expect(response).to be_redirect

        expect(current_user.receives_notification?(:system_updates_via_email)).to be true
        expect(current_user.receives_notification?(:system_updates_via_web)).to be true
        # expect(current_user.receives_notification?(:system_recommends_classes_via_email)).to be false
        # expect(current_user.receives_notification?(:system_recommends_classes_via_web)).to be false

        # expect(current_user.receives_reminder?(:hrs_72_via_sms)).to be true
        # expect(current_user.receives_reminder?(:hrs_72_via_email)).to be true
        #
        # expect(current_user.receives_reminder?(:hrs_24_via_email)).to be false
        # expect(current_user.receives_reminder?(:hrs_24_via_web)).to be false
      end
    end

    describe 'combined notifications' do
      it 'sets ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary setting with valid frequency' do
        expect(current_user.combined_notification_settings.count).to be_zero
        params = { combined_notification_settings: { '0' => {
          action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, frequency: '1,2,3', enabled: false
        } } }.merge(notifications_params_stub)
        put :update, params: params

        expect(response).to be_redirect
        setting = current_user.combined_notification_settings.where(action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name).first
        expect(setting.frequency).to eq [1, 2, 3]
        expect(setting.enabled).to eq false
      end

      it "resets setting's frequency if it is invalid" do
        CombinedNotificationSetting.notification_settings_for(current_user).each(&:save)
        params = { combined_notification_settings: { '0' => {
          action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, frequency: '-1,0;sdf,sdg,0', enabled: true
        } } }.merge(notifications_params_stub)
        put :update, params: params
        setting = current_user.combined_notification_settings.where(action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name).first
        expect(response).to be_redirect
        expect(setting.frequency).to eq [1, 3, 7]
        expect(setting.enabled).to eq true
      end
    end
  end
end
