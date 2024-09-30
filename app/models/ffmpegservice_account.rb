# frozen_string_literal: true
class FfmpegserviceAccount < ActiveRecord::Base
  include ModelConcerns::ActiveModel::Extensions

  module ServiceTypes
    MAIN        = 'main'
    IPCAM       = 'ipcam'
    RTMP        = 'rtmp'
    WEBRTC      = 'webrtc'

    ALL         = [MAIN, IPCAM, RTMP, WEBRTC].freeze
  end

  belongs_to :reserved_by, polymorphic: true
  belongs_to :studio_room
  belongs_to :user
  belongs_to :organization

  has_one :studio, through: :studio_room

  has_many :sessions
  has_many :stream_previews

  validates :custom_name, presence: true, if: lambda { |wa|
                                                wa.organization_id.present? && %w[rtmp ipcam].include?(wa.current_service.to_s)
                                              }
  validates :current_service, inclusion: { in: ServiceTypes::ALL }, unless: ->(wa) { wa.current_service.nil? }
  validates :delivery_method, presence: true, inclusion: { in: %w[pull push] }
  validates :transcoder_type, presence: true, inclusion: { in: %w[passthrough transcoded] }
  validates :studio_room_id, inclusion: { in: lambda { |wa|
                                                wa.organization.studio_rooms.pluck(:id)
                                              } }, unless: lambda { |wa|
                                                             wa.organization_id.nil? || wa.studio_room_id.nil?
                                                           }

  validate :source_url_validation, if: :source_url?

  scope :main, -> { where delivery_method: 'push', protocol: 'rtmp' }
  scope :rtmp, -> { where delivery_method: 'push', protocol: 'rtmp' }
  scope :ipcam, -> { where delivery_method: 'pull', protocol: 'rtsp' }
  scope :webrtc, -> { where delivery_method: 'push', protocol: 'webrtc' }

  scope :free, -> { where transcoder_type: 'passthrough' }
  scope :paid, -> { where transcoder_type: 'transcoded'  }

  scope :main_free, -> { where delivery_method: 'push', protocol: 'rtmp', transcoder_type: 'passthrough'  }
  scope :main_paid, -> { where delivery_method: 'push', protocol: 'rtmp', transcoder_type: 'transcoded'   }
  scope :rtmp_free, -> { where delivery_method: 'push', protocol: 'rtmp', transcoder_type: 'passthrough'  }
  scope :rtmp_paid, -> { where delivery_method: 'push', protocol: 'rtmp', transcoder_type: 'transcoded'   }
  scope :ipcam_free, -> { where delivery_method: 'pull', protocol: 'rtsp', transcoder_type: 'passthrough'  }
  scope :ipcam_paid, -> { where delivery_method: 'pull', protocol: 'rtsp', transcoder_type: 'transcoded'   }
  scope :webrtc_free, -> { where delivery_method: 'push', protocol: 'webrtc', transcoder_type: 'passthrough' }
  scope :webrtc_paid, -> { where delivery_method: 'push', protocol: 'webrtc', transcoder_type: 'transcoded' }

  scope :assigned, -> { where.not organization_id: nil }
  scope :not_assigned, -> { where organization_id: nil }
  scope :reserved, -> { where.not reserved_by_id: nil }
  scope :not_reserved, -> { where reserved_by_id: nil }

  scope :sandbox, -> { where sandbox: true }
  scope :not_sandbox, -> { where.not sandbox: true }

  after_commit on: %i[create update], if: proc { |wa| wa.saved_change_to_source_url? } do
    new_url = source_url.to_s.strip
    new_url = 'rtsp://localhost' if new_url.blank?
    Sender::Ffmpegservice.client(account: self).update_transcoder(transcoder: {
                                                            source_url: new_url,
                                                            protocol: URI.parse(new_url).scheme
                                                          })
  end

  after_update :sync_authentication, if: :saved_change_to_authentication?
  after_update :stream_status_changed, if: :saved_change_to_stream_status?

  def stream_m3u8_url
    if sandbox
      sandbox_url
    else
      hls_url
    end
  end

  def stream_stub_url
    '/stub/stream/index.m3u8'
  end

  def sandbox_url
    if stream_up?
      '/stub/sandbox/stream.m3u8'
    end
  end

  module Statuses
    OFF       = 'off'
    UP        = 'up'
    DOWN      = 'down'
    STARTING  = 'starting'

    ALL = [OFF, UP, DOWN, STARTING].freeze
  end

  Statuses::ALL.each do |const|
    define_method("stream_#{const}?") { stream_status == const }
    define_method("stream_#{const}!") { update_attribute(:stream_status, const) }
  end

  def as_json(_options = {})
    {
      id: id,
      user_id: user_id,
      organization_id: organization_id,
      server: server,
      port: port,
      stream_name: stream_name,
      username: username,
      password: password,
      hls_url: hls_url,
      stream_m3u8_url: stream_m3u8_url,
      stream_status: stream_status,
      stream_id: stream_id,
      transcoder_type: transcoder_type,
      stream_up: stream_up?,
      stream_down: stream_down?,
      stream_starting: stream_starting?,
      stream_off: stream_off?,
      source_url: source_url,
      sandbox: sandbox
    }
  end

  def self.transcoder_name_preffix
    prefix = Rails.application.credentials.backend.dig(:initialize, :ffmpegservice_account, :prefix)
    if prefix == 'DEFAULT'
      raise "Configure ffmpegservice_account prefix in app credentials override properly. #{Rails.application.credentials.global[:host]}"
    end

    "[#{prefix}]"
  end

  def transcoder_name
    str = "#{self.class.transcoder_name_preffix}#{id};"
    if organization.present?
      str += "o:#{organization.id};#{organization.always_present_title}"
    end
    if user.present?
      str += "u:#{user.id};#{user.public_display_name};#{user.email};"
    end
    ActiveSupport::Inflector.transliterate str[0..253], 'z'
  end

  def nullify!
    update_columns({ user_id: nil, organization_id: nil, custom_name: nil, current_service: nil, studio_room_id: nil,
                     updated_at: Time.now })
  end

  def default_custom_name
    default_custom_name = id.to_s

    if user.present?
      default_custom_name += " #{user.try(:public_display_name)}"
    elsif organization.present?
      default_custom_name += " #{organization.try(:always_present_title)}"
    end

    if transcoder_type == 'transcoded'
      default_custom_name += ' transcoded'
    end

    default_custom_name += case current_service
                           when 'rtmp'
                             ' Encoder'
                           when 'main'
                             ' WebCamera/MobileApp'
                           when 'ipcam'
                             ' IP Camera'
                           when 'webrtc'
                             ' WebRTC'
                           else
                             (delivery_method == 'pull') ? ' IP Camera' : ' WebCamera/MobileApp/Encoder'
                           end

    default_custom_name += (sandbox ? ' SANDBOX' : ' LIVE') unless Rails.env.production?

    default_custom_name
  end

  def authentication_on!
    update(authentication: true)
  end

  def authentication_off!
    update(authentication: false)
  end

  def assign_organization(organization)
    update(organization: organization)
  end

  def sync_authentication
    FfmpegserviceAccountJobs::SyncTranscoderAuthentication.perform_async(id)
  end

  def ongoing_session
    sessions.ongoing.order(start_at: :asc).last
  end

  def stream_status_changed
    sessions.ongoing.not_cancelled.find_each do |session|
      if stream_up?
        session.service_status_up! unless session.service_status_up?
      elsif stream_down?
        session.service_status_down! unless session.service_status_down?
      else
        session.service_status_off! unless session.service_status_off?
      end
    end
  end

  private

  # source_url required when using a file as the source for a stream and for RTMP and RTSP pull connections.
  # For RTMP and RTSP, enter the source encoder's web address, without the preceding protocol or trailing slash (/).
  # For files, enter the source file URL with the preceding protocol.
  def source_url_validation
    return if errors.include?(:source_url)
    return if delivery_method != 'pull'
    return if source_url.blank?

    self.source_url = source_url.to_s.strip

    uri = URI.parse(source_url)
    if uri.host.blank? || !(%w[rtmp rtsp].include? uri.scheme.to_s)
      errors.add(:source_url, 'does not look like valid URL')
    end
  end
end
