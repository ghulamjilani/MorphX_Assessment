# frozen_string_literal: true

module Control
  class TranscodeTask
    def initialize(transcode_task)
      @transcode_task = transcode_task
      @transcodable = @transcode_task.transcodable
      raise(ArgumentError, I18n.t('custom_libs.control.transcode_task.errors.transcodable_blank')) if @transcodable.blank?
    end

    def update_status
      status = client.status(@transcode_task.job_id)

      return false if status['status'].blank?

      @transcode_task.update(
        status: status['status'],
        percent: status['percent'],
        error: status['error'],
        error_description: status['error_description']
      )
    end

    private

    def client
      @client ||= Sender::Qencode.client
    end
  end
end
