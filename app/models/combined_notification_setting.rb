# frozen_string_literal: true
class CombinedNotificationSetting < ActiveRecord::Base
  include ModelConcerns::ActiveModel::Extensions

  serialize :frequency, Array
  ########  new functionality of notifications #########
  # serialize :frequency, Hash
  ########  new functionality of notifications #########

  has_many :combined_notifications, dependent: :destroy
  belongs_to :user

  validates :action_type, presence: true, uniqueness: { scope: [:user_id] }
  validate :frequency_presence

  def self.scenarios
    [
      ModelConcerns::Settings::CombinedNotificationsScenarios::PurchasesSummary
    ]
  end

  def self.notification_setting_for(scenario_name, user)
    scenario = find_scenario_by_name(scenario_name)

    scenario.new(user).combined_setting
  end

  # @param scenario_name - e.g. "livestream_purchase"
  def self.find_scenario_by_name(scenario_name)
    scenarios.find { |scenario| scenario.scenario_name.eql? scenario_name }.tap do |scenario|
      unless scenario
        raise NotificationScenarioNotFound, "Could not find scenario with name `#{scenario_name}'"
      end
    end
  end

  def self.notification_settings_for(user)
    scenarios.map { |scenario| scenario.new(user).combined_setting }
  end

  def self.update_settings(settings, user)
    settings.map do |setting|
      find_scenario_by_name(setting.symbolize_keys[:action_type]).new(user).update_settings setting
    end
  end

  # @param scenario_name - e.g. "livestream_purchase"
  # @param user - instance of User class
  # @param record - e.g. instance of Session class
  def self.perform_with_notice_count(scenario_name, user, record)
    scenario = find_scenario_by_name(scenario_name)
    scenario_obj = scenario.new(user)
    # > scenario_obj.class
    #=> Concerns::Settings::CombinedNotificationsScenarios::LivestreamPurchase
    notice_count = scenario_obj.increment_counter_for_record(record)

    ########  new functionality of notifications #########
    # notice_count = scenario_obj.combined_notification_satisfy?(record)
    ########  new functionality of notifications #########

    # CombinedNotification Load (0.8ms)  SELECT  "combined_notifications".* FROM "combined_notifications" WHERE "combined_notifications"."combined_notification_setting_id" = $1 AND "combined_notifications"."record_type" = 'Session' AND "combined_notifications"."record_id" = 8 LIMIT 1  [["combined_notification_setting_id", 1]]
    # SQL (0.5ms)  UPDATE "combined_notifications" SET "notices_count" = $1 WHERE "combined_notifications"."id" = $2  [["notices_count", 4], ["id", 1]]
    # => 4

    # scenario_obj.frequency
    #=> [1, 2, 3]

    ########  new functionality of notifications #########
    # yield(notice_count) if notice_count && scenario_obj.enabled?
    ########  new functionality of notifications #########

    if scenario_obj.frequency.include?(notice_count) && scenario_obj.enabled?
      yield(notice_count)
    end
  end

  private

  ########  new functionality of notifications #########
  # def frequency_presence
  #   return if everytime
  #   errors.add(:frequency, :blank) if frequency.blank?
  #   errors.add(:frequency, 'incorrect') if frequency[:count].nil? || frequency[:type].nil?
  # end
  ########  new functionality of notifications #########

  def frequency_presence
    if frequency.blank?
      errors.add(:frequency, :blank)
    end
  end

  class NotificationScenarioNotFound < StandardError
  end
end
