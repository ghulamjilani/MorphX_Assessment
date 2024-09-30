# frozen_string_literal: true
class WebrtcserviceRoom < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  module Statuses
    IN_PROGRESS = 'in-progress'
    COMPLETED = 'completed'

    ALL = [IN_PROGRESS, COMPLETED].freeze
  end

  belongs_to :session, required: true

  has_one :room, through: :session

  before_validation :generate_unique_name, unless: :unique_name?
  before_validation :set_record, if: ->(r) { r.record_enabled.nil? }
  before_validation :set_max_participants, if: ->(r) { r.max_participants.nil? }

  validates :unique_name, presence: true
  validates :sid, presence: true, uniqueness: true
  validates :status, inclusion: { in: Statuses::ALL }, if: ->(r) { r.status.present? }

  after_commit :status_changed_callbacks, if: :saved_change_to_status?

  delegate :recording_layout, to: :session, allow_nil: true
  delegate :organization, to: :session, allow_nil: true

  def completed?
    status == Statuses::COMPLETED
  end

  def inprogress?
    status == Statuses::IN_PROGRESS
  end

  def service_prefix
    @service_prefix = 'test' if Rails.env.test?
    @service_prefix ||= Rails.application.credentials.backend.dig(:initialize, :webrtcservice, :video, :service_prefix)
    raise 'backend:initialize:webrtcservice:service_prefix in application credentials is required' if @service_prefix.blank?

    @service_prefix
  end

  def env
    @env ||= Rails.env.first(2).upcase
  end

  def decode_name
    return {} if unique_name.blank? && generate_unique_name.blank?

    room_data = JSON.parse(unique_name)
    return {} unless room_data.is_a?(Hash)

    prefix = room_data['s']
    room_env = room_data['e']
    room_id = room_data['i']
    current_service = prefix && prefix === service_prefix && room_env === env
    room = current_service ? Room.find_by(id: room_id) : nil
    {
      room_id: room_id,
      env: room_env,
      service_prefix: prefix,
      current_service: current_service,
      room: room
    }
  rescue StandardError => e
    {}
  end

  def generate_unique_name
    self.unique_name = {
      s: service_prefix,
      e: env,
      i: room&.id
    }.to_json
  end

  private

  def set_record
    self.record_enabled = !!session&.do_record?
  end

  def set_max_participants
    self.max_participants = session&.max_number_of_immersive_participants.to_i + 1
  end

  def status_changed_callbacks
    Webrtcservice::RoomJobs::Usage::CollectInteractiveTimeJob.perform_async(id) if completed?
  end
end
