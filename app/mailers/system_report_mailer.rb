# frozen_string_literal: true

class SystemReportMailer < ApplicationMailer
  def video_is_corrupted(video_type, video_id)
    @video_type = video_type
    @video_id = video_id
    @subject = 'VIDEO IS CORRUPTED'
    platform_admins = Admin.where(receive_owner_mailing: true).pluck(:email)
    mail(to: platform_admins, subject: @subject)
  end

  def untracked_vod_objects_report(email, untracked_objects = {})
    @users = untracked_objects[:users]
    @rooms = untracked_objects[:rooms]
    @videos = untracked_objects[:videos]
    @channels = untracked_objects[:channels]
    @recordings = untracked_objects[:recordings]

    subject = 'VOD untracked objects report'

    mail to: email,
         subject:,
         template_path: 'system_report_mailer',
         template_name: 'untracked_vod_objects_report'
  end
end
