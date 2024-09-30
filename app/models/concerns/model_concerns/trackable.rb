# frozen_string_literal: true

module ModelConcerns
  module Trackable
    extend ActiveSupport::Concern

    included do
      has_many_documents :activities, class_name: '::Log::Activity', dependent: :destroy, as: :trackable
      def create_activity(*args)
        options = prepare_settings(*args)

        activities.create(options)
      end

      def create_activity!(*args)
        options = prepare_settings(*args)

        activities.create!(options)
      end

      def log_daily_activity(*args)
        create_or_update_activity(*args, created_after: Time.zone.now.beginning_of_day)
      end

      def create_or_update_activity(*args, created_after:)
        options = prepare_settings(*args)

        if (activity = Log::Activity.where({ :created_at.gt => created_after }.merge options).first)
          activity.touch
        else
          create_activity(*args)
        end
      end

      def prepare_settings(*args)
        raw_options = args.extract_options!
        key         = [args.first, raw_options.delete(:key)].compact.first

        raise NoKeyProvided, "No key provided for #{self.class.name}" unless key

        {
          key: key,
          trackable_id: id,
          trackable_type: self.class.name,
          owner_id: raw_options[:owner]&.id,
          owner_type: raw_options[:owner]&.class&.name,
          recipient_id: raw_options[:recipient]&.id,
          recipient_type: raw_options[:recipient]&.class&.name,
          parameters: raw_options[:parameters]
        }
      end
    end
  end
end
