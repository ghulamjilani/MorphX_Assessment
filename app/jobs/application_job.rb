# frozen_string_literal: true

class ApplicationJob
  include Sidekiq::Worker

  sidekiq_options queue: :default
  sidekiq_options retry: 1
  sidekiq_options backtrace: 20
  # sidekiq_options lock: :until_and_while_executing #gem sidekiq-unique-jobs
  #

  def debug_logger(name, data = {})
    @custom_logger ||= Logger.new "#{Rails.root}/log/jobs_#{self.class.to_s.underscore.tr('/',
                                                                                          '_')}.#{Time.now.utc.strftime('%Y-%m')}.#{Rails.env}.#{`hostname`.to_s.strip}.log"
    @custom_logger.debug("[#{jid}]: #{name} | #{data}")
    puts "[#{self.class}][#{Time.now.utc}][#{jid}]: #{name} | #{data}"
  rescue StandardError => e
    @custom_logger = nil
    Airbrake.notify(e)
  end
end
