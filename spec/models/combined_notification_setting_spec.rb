# frozen_string_literal: true
require 'spec_helper'

describe CombinedNotificationSetting do
  let(:user) { create(:user) }

  describe 'find scenario by name' do
    it 'throws exception if no scenario is found' do
      scenario_name = 'some-scenarion-which-does-not-exists'
      expect { described_class.find_scenario_by_name(scenario_name) }.to raise_error(
        CombinedNotificationSetting::NotificationScenarioNotFound, "Could not find scenario with name `#{scenario_name}'"
      )
    end
  end

  describe 'notification setting for user' do
    it 'returns new record of combined notification setting with default attrs if it does not exists' do
      attrs = %w[action_type enabled frequency]
      combined_notificaion_setting = described_class.notification_setting_for(
        ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, user
      )
      expect(combined_notificaion_setting.attributes.slice(*attrs).symbolize_keys)
        .to eq({ action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name,
                 enabled: true, frequency: [1, 3, 7] })
      expect(combined_notificaion_setting).to be_new_record
    end

    it 'returns existing record of combined notification setting' do
      described_class.notification_settings_for(user).each(&:save)
      combined_notificaion_setting = described_class.notification_setting_for(
        ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, user
      )
      expect(combined_notificaion_setting).not_to be_new_record
    end
  end

  describe 'notification settings for user' do
    it 'returns array of available combined notification settings for user' do
      settings = described_class.notification_settings_for(user)
      expect(settings).to be_kind_of Array
      expect(settings.length).to eq described_class.scenarios.length
    end
  end

  describe 'notifications update' do
    it 'updates combined notification settings from array of attributes' do
      attrs = [{ action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name,
                 enabled: false, frequency: [2, 3, 5] }]
      described_class.update_settings(attrs, user)
      combined_setting = user.combined_notification_settings.where(action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name).first
      expect(combined_setting.frequency).to eq [2, 3, 5]
      expect(combined_setting.enabled).to eq false
    end
  end

  describe 'perform with notice count' do
    describe 'when user does not have saved combined setting' do
      it 'does perform if current notice count is included in the list' do
        session = create(:immersive_session)
        user    = session.organizer

        arr = []
        5.times do
          described_class.perform_with_notice_count(
            ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, user, session
          ) do |notice_count|
            arr << notice_count
          end
        end
        expect(user.combined_notification_settings.count).to eq 1
        combined_notification = CombinedNotification.where(record: session).first
        expect(combined_notification.notices_count).to eq 5
        expect(arr).to eq [1, 3]
      end
    end

    describe 'when user have saved combined setting' do
      it 'does perform if current notice count is included in the list' do
        session = create(:immersive_session)
        user    = session.organizer
        attrs = [{ action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name,
                   enabled: true, frequency: [2, 3, 5] }]
        described_class.update_settings(attrs, user)

        arr = []
        6.times do
          described_class.perform_with_notice_count(
            ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, user, session
          ) do |notice_count|
            arr << notice_count
          end
        end

        combined_notification = CombinedNotification.where(record: session).first
        expect(combined_notification.notices_count).to eq 6
        expect(arr).to eq [2, 3, 5]
      end

      it 'does not do perform if current notice count is not included in the list' do
        session = create(:immersive_session)
        user    = session.organizer
        attrs = [{ action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name,
                   enabled: true, frequency: [3] }]
        described_class.update_settings(attrs, user)

        arr = []
        2.times do
          described_class.perform_with_notice_count(
            ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, user, session
          ) do |notice_count|
            arr << notice_count
          end
        end

        combined_notification = CombinedNotification.where(record: session).first
        expect(combined_notification.notices_count).to eq 2
        expect(arr).to eq []
      end

      it 'does not do perform if combined setting is not enabled' do
        session = create(:immersive_session)
        user    = session.organizer
        attrs = [{ action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name,
                   enabled: false, frequency: [1, 2, 3] }]
        described_class.update_settings(attrs, user)
        arr = []
        3.times do
          described_class.perform_with_notice_count(
            ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, user, session
          ) do |notice_count|
            arr << notice_count
          end
        end

        combined_notification = CombinedNotification.where(record: session).first
        expect(combined_notification.notices_count).to eq 3
        expect(arr).to eq []
      end
    end
  end
end

########  new functionality of notifications #########
# require 'spec_helper'

# describe CombinedNotificationSetting do
#   let(:user) { create(:user) }
#   describe "find scenario by name" do
#     it "should throw exception if no scenario is found" do
#       scenario_name = 'some-scenarion-which-does-not-exists'
#       expect { CombinedNotificationSetting.find_scenario_by_name(scenario_name) }.to raise_error(
#           CombinedNotificationSetting::NotificationScenarioNotFound, "Could not find scenario with name `#{scenario_name}'"
#         )
#     end

#   end

#   describe "notification setting for user" do
#     it "should return new record of combined notification setting with default attrs if it does not exists" do
#       attrs = ['action_type', 'enabled', 'everytime', 'frequency']
#       combined_notificaion_setting = CombinedNotificationSetting.notification_setting_for(ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, user)
#       expect(combined_notificaion_setting.attributes.slice(*attrs).symbolize_keys).
#         to eq({action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, everytime: true, enabled: true, frequency: {count: 1, type: 'day'}})
#       expect(combined_notificaion_setting).to be_new_record
#     end
#     it "should return existing record of combined notification setting" do
#       CombinedNotificationSetting.notification_settings_for(user).each(&:save)
#       combined_notificaion_setting = CombinedNotificationSetting.notification_setting_for(ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, user)
#       expect(combined_notificaion_setting).not_to be_new_record
#     end
#   end

#   describe "notification settings for user" do
#     it "should return array of available combined notification settings for user" do
#       settings = CombinedNotificationSetting.notification_settings_for(user)
#       expect(settings).to be_kind_of Array
#       expect(settings.length).to eq CombinedNotificationSetting.scenarios.length
#     end
#   end

#   describe "notifications update" do
#     it "should update combined notification settings from array of attributes" do
#       attrs = [{action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, everytime: true, enabled: false, frequency: {count: 5, type: 'week'}}]
#       CombinedNotificationSetting.update_settings(attrs, user)
#       combined_setting = user.combined_notification_settings.where(action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name).first
#       expect(combined_setting.frequency).to eq ({"count"=>5, "type"=>"week"})
#       expect(combined_setting.enabled).to eq false
#     end
#   end

#   describe "perform with notice count" do
#     describe "when user does not have saved combined setting" do

#       it "should ot perform" do
#         session = create(:immersive_session)
#         user    = session.organizer
#         arr = []
#         1.times do
#           CombinedNotificationSetting.perform_with_notice_count(ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, user, session) do |notice_count|
#             arr << notice_count
#           end
#         end
#         expect(user.combined_notification_settings.count).to eq 1
#         expect(arr).to eq [true]
#       end

#     end

#     describe "when user have saved combined setting" do

#       it "should do perform if current notice count is included in the list" do
#         session = create(:immersive_session)
#         user    = session.organizer
#         attrs = [{action_type: ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, enabled: true, frequency: {count: 1, type: 'hour'}}]
#         CombinedNotificationSetting.update_settings(attrs, user)

#         arr = []
#         1.times do
#           CombinedNotificationSetting.perform_with_notice_count(ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary.scenario_name, user, session) do |notice_count|
#             arr << notice_count
#           end
#         end
#         expect(user.combined_notification_settings.count).to eq 1
#         expect(arr).to eq [true]
#       end
#     end
#   end
# end
########  new functionality of notifications #########
