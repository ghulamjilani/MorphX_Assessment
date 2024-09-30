# frozen_string_literal: true

# table-less model for formtastic
# http://railscasts.com/episodes/326-activeattr
module ModelConcerns::Settings
  class Notification
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    ALL_BASE = %i[
      exclusive_offers
      follow_me
      newsletter
      participant_invited_to_abstract_session
      purchases_summary_for_organizer
      system_announces_new_classes
      system_recommends_classes
      system_updates
      user_accepted_or_rejected_your_invitation
      wishlist_session
      start_reminder

      hrs_72
      hrs_24
      hrs_6
      hrs_1
      mins_15

      session_no_stream_stop_scheduled
      session_no_presenter_stop_scheduled
    ].freeze

    ALL = ALL_BASE.inject([]) do |memo, base_key|
      %i[via_web via_email via_sms].each do |base_key_suffix|
        const_name = "#{base_key.upcase}_#{base_key_suffix.upcase}"
        key_name = "#{base_key}_#{base_key_suffix.downcase}"

        Rails.logger.debug "just set #{const_name} constant setting"
        # just set EXCLUSIVE_OFFERS_VIA_WEB constant setting
        # just set EXCLUSIVE_OFFERS_VIA_EMAIL constant setting
        # just set EXCLUSIVE_OFFERS_VIA_SMS constant setting
        # just set FOLLOW_ME_VIA_WEB constant setting
        # just set FOLLOW_ME_VIA_EMAIL constant setting
        # just set FOLLOW_ME_VIA_SMS constant setting
        # just set NEWSLETTER_VIA_WEB constant setting
        # just set NEWSLETTER_VIA_EMAIL constant setting
        # just set NEWSLETTER_VIA_SMS constant setting
        # just set PARTICIPANT_INVITED_TO_ABSTRACT_SESSION_VIA_WEB constant setting
        # just set PARTICIPANT_INVITED_TO_ABSTRACT_SESSION_VIA_EMAIL constant setting
        # just set PARTICIPANT_INVITED_TO_ABSTRACT_SESSION_VIA_SMS constant setting
        # just set PURCHASES_SUMMARY_FOR_ORGANIZER_VIA_WEB constant setting
        # just set PURCHASES_SUMMARY_FOR_ORGANIZER_VIA_EMAIL constant setting
        # just set PURCHASES_SUMMARY_FOR_ORGANIZER_VIA_SMS constant setting
        # just set SYSTEM_ANNOUNCES_NEW_CLASSES_VIA_WEB constant setting
        # just set SYSTEM_ANNOUNCES_NEW_CLASSES_VIA_EMAIL constant setting
        # just set SYSTEM_ANNOUNCES_NEW_CLASSES_VIA_SMS constant setting
        # just set SYSTEM_RECOMMENDS_CLASSES_VIA_WEB constant setting
        # just set SYSTEM_RECOMMENDS_CLASSES_VIA_EMAIL constant setting
        # just set SYSTEM_RECOMMENDS_CLASSES_VIA_SMS constant setting
        # just set SYSTEM_UPDATES_VIA_WEB constant setting
        # just set SYSTEM_UPDATES_VIA_EMAIL constant setting
        # just set SYSTEM_UPDATES_VIA_SMS constant setting
        # just set USER_ACCEPTED_OR_REJECTED_YOUR_INVITATION_VIA_WEB constant setting
        # just set USER_ACCEPTED_OR_REJECTED_YOUR_INVITATION_VIA_EMAIL constant setting
        # just set USER_ACCEPTED_OR_REJECTED_YOUR_INVITATION_VIA_SMS constant setting
        # just set WISHLIST_SESSION_VIA_WEB constant setting
        # just set WISHLIST_SESSION_VIA_EMAIL constant setting
        # just set WISHLIST_SESSION_VIA_SMS constant setting
        # just set START_REMINDER_VIA_WEB constant setting
        # just set START_REMINDER_VIA_EMAIL constant setting
        # just set START_REMINDER_VIA_SMS constant setting
        # just set HRS_72_VIA_WEB constant setting
        # just set HRS_72_VIA_EMAIL constant setting
        # just set HRS_72_VIA_SMS constant setting
        # just set HRS_24_VIA_WEB constant setting
        # just set HRS_24_VIA_EMAIL constant setting
        # just set HRS_24_VIA_SMS constant setting
        # just set HRS_6_VIA_WEB constant setting
        # just set HRS_6_VIA_EMAIL constant setting
        # just set HRS_6_VIA_SMS constant setting
        # just set HRS_1_VIA_WEB constant setting
        # just set HRS_1_VIA_EMAIL constant setting
        # just set HRS_1_VIA_SMS constant setting
        # just set MINS_15_VIA_WEB constant setting
        # just set MINS_15_VIA_EMAIL constant setting
        # just set MINS_15_VIA_SMS constant setting
        # just set SESSION_NO_STREAM_STOP_SCHEDULED_VIA_WEB constant setting
        # just set SESSION_NO_STREAM_STOP_SCHEDULED_VIA_EMAIL constant setting
        # just set SESSION_NO_STREAM_STOP_SCHEDULED_VIA_SMS constant setting
        # just set SESSION_NO_PRESENTER_STOP_SCHEDULED_VIA_WEB constant setting
        # just set SESSION_NO_PRESENTER_STOP_SCHEDULED_VIA_EMAIL constant setting
        # just set SESSION_NO_PRESENTER_STOP_SCHEDULED_VIA_SMS constant setting

        const_set(const_name, key_name)
        __send__(:attr_accessor, key_name)
        memo << key_name
      end
      memo
    end.freeze

    def self.initialize_from_scoped_settings(user)
      _persisted_settings = RailsSettings::ScopedSettings.all.where(thing: user)

      new.tap do |notification|
        missing_persisted_attributes = ALL - _persisted_settings.collect(&:var)

        # NOTE: _via_sms options have to be explicitely turned on
        missing_persisted_attributes.each do |attribute_name|
          if attribute_name.ends_with?('_via_sms')
            notification.send("#{attribute_name}=", '0')
          else
            notification.send("#{attribute_name}=", '1')
          end
        end

        _persisted_settings.each do |scoped_setting|
          if notification.respond_to?("#{scoped_setting.var}=")
            notification.send("#{scoped_setting.var}=",
                              scoped_setting.value)
          end
        end
      end
    end

    # NOTE: do not delete this method!
    #      it is implemented explicitely because this is a virtual tableless model
    def initialize(attributes = {})
      missing_persisted_attributes = ALL - attributes.dup.to_h.symbolize_keys.keys
      # NOTE: _via_sms options have to be explicitely turned on
      missing_persisted_attributes.each do |attribute_name|
        if attribute_name.ends_with?('_via_sms')
          send("#{attribute_name}=", '0')
        else
          send("#{attribute_name}=", '1')
        end
      end

      attributes.each do |name, value|
        send("#{name}=", value) if respond_to?("#{name}=")
      end
    end

    def persisted?
      false
    end

    def save_for(user)
      keys_for_saving.each do |key|
        value = instance_variable_get("@#{key}")
        user.settings.send("#{key}=", value)
      end
    end

    private

    # @return [String]
    def keys_for_saving
      instance_variables.collect { |v| v.to_s.delete('@') }
    end
  end
end
