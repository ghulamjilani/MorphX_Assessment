# frozen_string_literal: true

class FfmpegserviceStreamMailerPreview < ApplicationMailerPreview
  def stream_stopped
    wa_id = FfmpegserviceAccount.where.not(organization_id: nil).order('RANDOM()').limit(1).first.id
    FfmpegserviceStreamMailer.stream_stopped(wa_id, Time.now.utc.to_s)
  end
end
