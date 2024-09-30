# frozen_string_literal: true

module ModelConcerns::User::HasFfmpegserviceAccounts
  extend ActiveSupport::Concern

  included do
    has_many :wa_main_free, lambda {
                              main_free.where(current_service: 'main')
                            }, class_name: 'FfmpegserviceAccount', inverse_of: :user, foreign_key: :user_id
    has_many :wa_main_paid, lambda {
                              main_paid.where(current_service: 'main')
                            }, class_name: 'FfmpegserviceAccount', inverse_of: :user, foreign_key: :user_id
    has_many :wa_rtmp_free, lambda {
                              rtmp_free.where(current_service: 'rtmp')
                            }, class_name: 'FfmpegserviceAccount', inverse_of: :user, foreign_key: :user_id
    has_many :wa_rtmp_paid, lambda {
                              rtmp_paid.where(current_service: 'rtmp')
                            }, class_name: 'FfmpegserviceAccount', inverse_of: :user, foreign_key: :user_id
    has_many :wa_ipcam_free, lambda {
                               ipcam_free.where(current_service: 'ipcam')
                             }, class_name: 'FfmpegserviceAccount', inverse_of: :user, foreign_key: :user_id
    has_many :wa_ipcam_paid, lambda {
                               ipcam_paid.where(current_service: 'ipcam')
                             }, class_name: 'FfmpegserviceAccount', inverse_of: :user, foreign_key: :user_id

    has_many :ffmpegservice_accounts, class_name: 'FfmpegserviceAccount', inverse_of: :user, foreign_key: :user_id

    after_destroy :nullify_wa
  end

  def ffmpegservice_account(current_service:, type:, organization_id:)
    send("wa_#{current_service}_#{type}").where(organization_id: organization_id).first
  end

  def wa_service_by(service_type:)
    case service_type
    when ::Room::ServiceTypes::RTMP
      'rtmp'
    when ::Room::ServiceTypes::IPCAM
      'ipcam'
    when ::Room::ServiceTypes::MOBILE
      'main'
    else
      raise 'Unknown status'
    end
  end

  def ffmpegservice_account_by(service_type:, organization_id:)
    organization = Organization.find(organization_id)
    current_service = wa_service_by(service_type: service_type)
    wa_type = organization.ffmpegservice_transcode ? 'paid' : 'free'
    ffmpegservice_account(current_service: current_service, type: wa_type, organization_id: organization_id)
  end

  def assign_ffmpegservice_account(current_service:, type:, organization_id:)
    if organization_id.blank?
      raise ArgumentError, 'organization_id missing'
    end

    wa = ffmpegservice_account(current_service: current_service, type: type, organization_id: organization_id)
    if wa && current_service.to_s == 'main'
      return wa
    end

    Organization.find(organization_id).assign_ffmpegservice_account(current_service: current_service, type: type, user_id: id)
  rescue StandardError => e
    Airbrake.notify(
      e.message,
      parameters: {
        user_id: id,
        current_service: current_service,
        type: type,
        organization_id: organization_id
      }
    )
    nil
  end

  private

  def nullify_wa
    ffmpegservice_accounts.find_each.with_index do |wa, index|
      FfmpegserviceAccountJobs::EnableTranscoderAuthentication.perform_at((index * 12).seconds.from_now, wa.id)
    end
    ffmpegservice_accounts.update_all(
      {
        organization_id: nil,
        user_id: nil,
        reserved_by_id: nil,
        custom_name: nil,
        current_service: nil,
        studio_room_id: nil,
        authentication: true,
        updated_at: Time.now
      }
    )
  end
end
