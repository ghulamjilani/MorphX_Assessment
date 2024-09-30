# frozen_string_literal: true

class Webhook::V1::MindBodyOnlineController < ActionController::Base
  skip_before_action :verify_authenticity_token

  # Event Base
  # {
  #     "messageId": "ASwFMoA2Q5UKw69g3RDbvU",
  #     "eventId": "site.created",
  #     "eventSchemaVersion": 1,
  #     "eventInstanceOriginationDateTime": "2018-04-18T10:02:55Z",
  #     "eventData": {eventDataObject}
  # }
  def create
    data = params.to_unsafe_h

    case data['eventId']
    when 'site.created', 'site.updated'
      MindBodyJobs::Webhook::Site::CreateUpdate.perform_async(data['eventData'])
    when 'site.deactivated'
      MindBodyJobs::Webhook::Site::Deactivate.perform_async(data['eventData'])
    when 'location.created', 'location.updated'
      MindBodyJobs::Webhook::Location::CreateUpdate.perform_async(data['eventData'])
    when 'location.deactivated'
      MindBodyJobs::Webhook::Location::Deactivated.perform_async(data['eventData'])
    when 'classSchedule.created', 'classSchedule.updated'
      MindBodyJobs::Webhook::ClassSchedule::CreateUpdate.perform_async(data['eventData'])
    when 'classSchedule.cancelled'
      MindBodyJobs::Webhook::ClassSchedule::Cancelled.perform_async(data['eventData'])
    when 'classDescription.updated'
      MindBodyJobs::Webhook::ClassDescription::CreateUpdate.perform_async(data['eventData'])
    when 'class.updated'
      MindBodyJobs::Webhook::ClassRoom::CreateUpdate.perform_async(data['eventData'])
    when 'staff.created', 'staff.updated'
      MindBodyJobs::Webhook::Staff::CreateUpdate.perform_async(data['eventData'])
    when 'staff.deactivated'
      MindBodyJobs::Webhook::Staff::Deactivated.perform_async(data['eventData'])
    else
      Airbrake.notify('[MindBodyOnline] unknown event type')
    end

    debug_logger('webhook', data)

    head :ok
  end

  private

  def debug_logger(name, data = {})
    @custom_logger ||= Logger.new "#{Rails.root}/log/#{self.class.to_s.underscore.tr('/',
                                                                                     '_')}.#{Time.now.utc.strftime('%Y-%m')}.#{Rails.env}.#{`hostname`.to_s.strip}.log"
    @custom_logger.debug("[#{request&.remote_ip}]: #{name} | #{data}")
    puts "[#{self.class}][#{Time.now.utc}][#{request&.remote_ip}]: #{name} | #{data}"
  rescue StandardError => e
    Airbrake.notify(e)
  end
end
