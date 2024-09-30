# frozen_string_literal: true

module ModelConcerns::Settings::CombinedNotificationsScenarios
  class AbstractScenario
    ########  new functionality of notifications #########
    # delegate :everytime, :frequency, :enabled?, to: :combined_setting
    ########  new functionality of notifications #########

    delegate :frequency, :enabled?, to: :combined_setting

    def self.scenario_name
      raise NotInheritedError, 'Abstract class must be overridden'
    end

    def initialize(user)
      if self.class == AbstractScenario
        raise NotInheritedError, 'Abstract class must be overridden'
      end

      @user = user
    end

    def combined_setting
      @combined_setting ||= begin
        setting = @user.combined_notification_settings.where(action_type: self.class.scenario_name).first
        setting || build_default_setting
      end
    end

    def update_settings(attrs)
      ########  new functionality of notifications #########
      # attrs = attrs.with_indifferent_access.slice(:enabled, :everytime, :frequency)
      ########  new functionality of notifications #########
      attrs = attrs.with_indifferent_access.slice(:enabled, :frequency)
      combined_setting.assign_attributes(attrs)
      combined_setting.save
      combined_setting
    end

    # @param record - e.g. instance of Session class
    def increment_counter_for_record(record)
      notification = combined_setting.combined_notifications.find_or_initialize_by(record: record)
      notification.increment(:notices_count, 1)
      notification.save
      notification.notices_count
    end

    ########  new functionality of notifications #########
    # def combined_notification_satisfy?(record)
    #   notification = combined_setting.combined_notifications.find_or_initialize_by(record: record)
    #   if combined_setting.everytime
    #     notification.new_record? ? notification.save : notification.touch
    #     return true
    #   end
    #   count = combined_setting.frequency[:count]
    #   type = combined_setting.frequency[:type]
    #   if notification.new_record? || combined_setting.updated_at < Time.now - count.send(type)
    #     notification.new_record? ? notification.save : notification.touch
    #     return true
    #   end
    #   false
    # end
    ########  new functionality of notifications #########

    private

    def build_default_setting
      @user.combined_notification_settings.build({ action_type: self.class.scenario_name, enabled: true,
                                                   frequency: [1, 3, 7] })
    end

    ########  new functionality of notifications #########
    # def build_default_setting
    #   @user.combined_notification_settings.build({action_type: self.class.scenario_name, everytime: true, enabled: true, frequency: {count: 1, type: 'day'}})
    # end
    ########  new functionality of notifications #########
  end
end
