# frozen_string_literal: true

Dir["#{Rails.root}/app/custom_libs/zoom/webhook/events/*.rb"].each { |file| require_dependency file }
module Zoom::Webhook
  module Handler
    def self.handle(params:)
      event_classes = Zoom::Webhook::Base.subclasses.find_all do |handler|
        handler.event_type == params['event']
      end
      if event_classes.blank?
        :handler_not_implemented
      else
        begin
          event_classes.each { |klass| klass.new(event: params).perform }
        rescue StandardError => e
          return false
        end
      end
    end
  end
end
# {"event"=>"recording.paused", "payload"=>{"account_id"=>"zI8tjMxnTHmSj0vLMQ1_wA", "object"=>{"uuid"=>"EnHa3FlBSWCo5yOup69pOw==", "id"=>9206225653, "host_id"=>"OdT9FmVRSg6epnzDHUm2vw", "topic"=>"Daryna Varankover's Personal Meeting Room", "type"=>4, "start_time"=>"2021-02-01T16:16:00Z", "timezone"=>"Europe/Kiev", "duration"=>0, "recording_file"=>{"recording_start"=>"2021-02-01T16:22:25Z", "recording_end"=>""}}}, "event_ts"=>1612196582362, "controller"=>"webhook/v1/zoom", "action"=>"create", "zoom"=>{"event"=>"recording.paused", "payload"=>{"account_id"=>"zI8tjMxnTHmSj0vLMQ1_wA", "object"=>{"uuid"=>"EnHa3FlBSWCo5yOup69pOw==", "id"=>9206225653, "host_id"=>"OdT9FmVRSg6epnzDHUm2vw", "topic"=>"Daryna Varankover's Personal Meeting Room", "type"=>4, "start_time"=>"2021-02-01T16:16:00Z", "timezone"=>"Europe/Kiev", "duration"=>0, "recording_file"=>{"recording_start"=>"2021-02-01T16:22:25Z", "recording_end"=>""}}}, "event_ts"=>1612196582362}}
# {"event"=>"recording.resumed", "payload"=>{"account_id"=>"zI8tjMxnTHmSj0vLMQ1_wA", "object"=>{"uuid"=>"EnHa3FlBSWCo5yOup69pOw==", "id"=>9206225653, "host_id"=>"OdT9FmVRSg6epnzDHUm2vw", "topic"=>"Daryna Varankover's Personal Meeting Room", "type"=>4, "start_time"=>"2021-02-01T16:16:00Z", "timezone"=>"Europe/Kiev", "duration"=>0, "recording_file"=>{"recording_start"=>"2021-02-01T16:22:25Z", "recording_end"=>""}}}, "event_ts"=>1612196608435, "controller"=>"webhook/v1/zoom", "action"=>"create", "zoom"=>{"event"=>"recording.resumed", "payload"=>{"account_id"=>"zI8tjMxnTHmSj0vLMQ1_wA", "object"=>{"uuid"=>"EnHa3FlBSWCo5yOup69pOw==", "id"=>9206225653, "host_id"=>"OdT9FmVRSg6epnzDHUm2vw", "topic"=>"Daryna Varankover's Personal Meeting Room", "type"=>4, "start_time"=>"2021-02-01T16:16:00Z", "timezone"=>"Europe/Kiev", "duration"=>0, "recording_file"=>{"recording_start"=>"2021-02-01T16:22:25Z", "recording_end"=>""}}}, "event_ts"=>1612196608435}}
#
#
#
