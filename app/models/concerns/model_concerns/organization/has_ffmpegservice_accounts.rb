# frozen_string_literal: true

module ModelConcerns::Organization::HasFfmpegserviceAccounts
  extend ActiveSupport::Concern

  included do
    has_many :wa_main_free, lambda {
                              main_free.where(current_service: 'main')
                            }, class_name: 'FfmpegserviceAccount', inverse_of: :organization, foreign_key: :organization_id
    has_many :wa_main_paid, lambda {
                              main_paid.where(current_service: 'main')
                            }, class_name: 'FfmpegserviceAccount', inverse_of: :organization, foreign_key: :organization_id
    has_many :wa_rtmp_free, lambda {
                              rtmp_free.where(current_service: 'rtmp')
                            }, class_name: 'FfmpegserviceAccount', inverse_of: :organization, foreign_key: :organization_id
    has_many :wa_rtmp_paid, lambda {
                              rtmp_paid.where(current_service: 'rtmp')
                            }, class_name: 'FfmpegserviceAccount', inverse_of: :organization, foreign_key: :organization_id
    has_many :wa_ipcam_free, lambda {
                               ipcam_free.where(current_service: 'ipcam')
                             }, class_name: 'FfmpegserviceAccount', inverse_of: :organization, foreign_key: :organization_id
    has_many :wa_ipcam_paid, lambda {
                               ipcam_paid.where(current_service: 'ipcam')
                             }, class_name: 'FfmpegserviceAccount', inverse_of: :organization, foreign_key: :organization_id

    has_many :ffmpegservice_accounts, class_name: 'FfmpegserviceAccount', inverse_of: :organization, foreign_key: :organization_id
    has_many :reserved_ffmpegservice_accounts, class_name: 'FfmpegserviceAccount', as: :reserved_by

    after_destroy :nullify_wa
  end

  def ffmpegservice_account(current_service:, type:, user_id: nil)
    query = send("wa_#{current_service}_#{type}")

    if current_service.to_sym == :main && user_id.present?
      query = query.where(user_id: user_id)
    end

    query.order('sandbox asc').first
  end

  def wa_service_by(service_type:)
    case service_type.to_s
    when ::Room::ServiceTypes::WEBRTC
      'webrtc'
    when ::Room::ServiceTypes::RTMP
      'rtmp'
    when ::Room::ServiceTypes::IPCAM
      'ipcam'
    when ::Room::ServiceTypes::MOBILE
      'main'
    else
      raise "Unknown service type '#{service_type}'"
    end
  end

  def ffmpegservice_account_by(service_type:, user_id: nil)
    current_service = wa_service_by(service_type: service_type)
    wa_type = ffmpegservice_transcode ? 'paid' : 'free'
    ffmpegservice_account(current_service: current_service, type: wa_type, user_id: user_id)
  end

  def assign_ffmpegservice_account(current_service:, type:, user_id: nil)
    raise 'Organization is not ready for ffmpegservice account' unless ready_for_wa?

    current_service = current_service.to_sym

    query = FfmpegserviceAccount.not_assigned.not_reserved
    query = case current_service
            when :rtmp
              query.rtmp
            when :ipcam
              query.ipcam
            when :webrtc
              query.webrtc
            else
              query.main
            end

    query = (type.to_sym == :paid) ? query.paid : query.free
    wa = query.order('sandbox asc').limit(1).first

    if wa.blank? && %i[main webrtc].include?(current_service)
      wa = FfmpegserviceAccount.where(organization_id: id, user_id: nil, current_service: current_service,
                              transcoder_type: ((type.to_sym == :paid) ? :transcoded : :passthrough)).order('sandbox asc').first
    end

    raise "Can't assign '#{current_service}' and '#{type}' account. Try again later" if wa.blank?

    new_attributes = {
      organization_id: id,
      current_service: current_service,
      authentication: (current_service != :main)
    }
    if %i[main webrtc].include?(current_service)
      new_attributes[:user_id] = user_id
      Sender::Ffmpegservice.client(account: wa).update_transcoder(transcoder: { disable_authentication: true })
    end
    new_attributes[:custom_name] =
      FfmpegserviceAccount.new(organization_id: id, user_id: user_id, current_service: current_service,
                       transcoder_type: (ffmpegservice_transcode ? 'transcoded' : 'passthrough')).default_custom_name
    wa.update(new_attributes)
    wa
  rescue StandardError => e
    Airbrake.notify(
      e.message,
      parameters: {
        organization_id: id,
        current_service: current_service,
        type: type,
        user_id: user_id
      }
    )
    nil
  end

  def toggle_switch_transcode
    %w[main rtmp ipcam].each do |service_type|
      if ffmpegservice_account(current_service: service_type, type: (ffmpegservice_transcode ? :paid : :free)).present?
        assign_ffmpegservice_account(current_service: service_type, type: (ffmpegservice_transcode ? :free : :paid))
      end
    end
    update_column(:ffmpegservice_transcode, !ffmpegservice_transcode)
  rescue StandardError => e
    errors.add(:ffmpegservice_transcode, e.message)
  end

  def find_or_assign_wa(user_id:, service_type:)
    current_service = wa_service_by(service_type: service_type)
    relation = ffmpegservice_accounts.where(current_service: current_service,
                                    transcoder_type: (ffmpegservice_transcode ? 'transcoded' : 'passthrough')).order('sandbox asc')
    wa = if current_service == 'main'
           relation.find_by(user_id: user_id)
         else
           relation.first
         end

    unless wa
      type = ffmpegservice_transcode ? :paid : :free
      wa = assign_ffmpegservice_account(current_service: current_service, type: type, user_id: user_id)
    end
    wa
  end

  private

  def nullify_wa
    ffmpegservice_accounts.where(protocol: :rtmp).find_each.with_index do |wa, index|
      if wa.protocol.to_sym == :rtmp
        FfmpegserviceAccountJobs::EnableTranscoderAuthentication.perform_at((index * 12).seconds.from_now,
                                                                    wa.id)
      end
    end
    ffmpegservice_accounts.where(protocol: :rtmp).update_all({ authentication: true })
    ffmpegservice_accounts.update_all(
      {
        organization_id: nil,
        user_id: nil,
        reserved_by_id: nil,
        custom_name: nil,
        current_service: nil,
        studio_room_id: nil,
        updated_at: Time.now
      }
    )
  end
end
