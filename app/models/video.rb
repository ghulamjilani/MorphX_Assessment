# frozen_string_literal: true
class Video < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::HasShortUrl
  include ModelConcerns::Video::PgSearchable
  include ModelConcerns::Trackable
  include ModelConcerns::ActiveModel::Extensions
  include ModelConcerns::Shared::Viewable
  include ModelConcerns::Shared::HasPromoWeight
  include ModelConcerns::Shared::Transcodable
  include ModelConcerns::Shared::HasHlsPaths
  include ModelConcerns::Shared::HasStorageRecords
  include ModelConcerns::Shared::HasLists
  include ModelConcerns::Shared::Blockable
  include ModelConcerns::Shared::ActsAsWishlistItem

  acts_as_ordered_taggable_on :tags

  belongs_to :room
  has_one :session, through: :room, source: :abstract_session, source_type: 'Session', class_name: 'Session', touch: true
  belongs_to :user
  has_one :channel, through: :session
  has_one :organization, through: :channel
  has_one :video_image, dependent: :destroy
  has_many :reviews, through: :session
  has_many :comments, through: :session
  has_many :polls, class_name: 'Poll::Poll', as: :model, dependent: :destroy

  accepts_nested_attributes_for :video_image, allow_destroy: true
  accepts_nested_attributes_for :session, update_only: true

  delegate :id, to: :session, prefix: true, allow_nil: true
  delegate :id, to: :organization, prefix: true, allow_nil: true
  delegate :id, to: :channel, prefix: true, allow_nil: true

  module Statuses
    FOUND = 'found' # found new completed ffmpegservice recording or new completed webrtcservice composition
    TRANSFER = 'transfer' # job that downloads from ffmpegservice and webrtcservice to s3
    ERROR = 'error' # eny error
    DOWNLOADED = 'downloaded' # downloaded to s3
    ORIGINAL_VERIFIED = 'original_verified' # download checked and displayed in dashboard
    READY_TO_TR = 'ready_to_tr' # downloaded, ready to transcode
    TRANSCODING = 'transcoding' # transcoding
    TRANSCODED = 'transcoded' # transcode completed but not checked
    DONE = 'done' # transcoded files checked

    LIVESTREAM = 'livestream' # not used
    PRECAST = 'pre-cast' # not used
    RTMP = 'rtmp' # not used

    ALL = [FOUND, TRANSFER, ERROR, DOWNLOADED, ORIGINAL_VERIFIED, READY_TO_TR, TRANSCODING, TRANSCODED, DONE, PRECAST, LIVESTREAM, RTMP].freeze

    PROCESSING = [READY_TO_TR, TRANSCODING, TRANSCODED].freeze

    USER_ALLOWED = [ORIGINAL_VERIFIED, READY_TO_TR, TRANSCODING, TRANSCODED, DONE].freeze
  end

  Statuses::ALL.each do |const|
    define_method("status_#{const}?") { status == const }
  end

  def processing?
    Statuses::PROCESSING.include?(status.to_s)
  end

  # enum status: {
  #     found:        0,
  #     ready_to_tr:  1,
  #     transcoding:  2,
  #     done:         3,
  #     error:        4,
  # }

  SHARE_IMAGE_WIDTH = 1280
  SHARE_IMAGE_HEIGHT = 720

  # downloaded but not transcoded videos have to be removed after this time interval
  DELETE_AFTER_DAYS = Rails.env.production? ? 60 : 3

  # validates :room, :user, presence: true
  validates :status, presence: true, inclusion: { in: Statuses::ALL }
  validate :validate_status_ready_to_tr, on: :update

  scope :available, -> { where(status: Statuses::DONE).where(deleted_at: nil) }
  scope :visible, -> { where(show_on_profile: true, fake: false) }

  scope :not_fake, -> { where(fake: false, deleted_at: nil) }
  scope :for_home_page, -> { where(show_on_home: true, deleted_at: nil, fake: false) }
  scope :waiting_admin, -> { where(status: Statuses::DOWNLOADED).where(deleted_at: nil) }
  scope :something_wrong, -> { where(status: 'error', ffmpegservice_state: 'completed').where(deleted_at: nil) }
  scope :allowed_user_statuses, -> { where(status: Statuses::USER_ALLOWED) }
  scope :published, -> { where.not(published: nil) }
  scope :processing, -> { where(status: Statuses::PROCESSING) }
  scope :not_published, -> { where(published: nil) }
  scope :not_deleted, -> { where(deleted_at: nil) }

  before_validation :sanitize_description, if: :description_changed?
  after_create :update_short_urls, if: ->(v) { v.room.present? }
  after_create :set_default_title
  after_commit :status_changed_callbacks, if: :saved_change_to_status?
  after_commit :notify_session_video_published, if: :saved_change_to_published?

  delegate :show_comments, to: :channel
  delegate :show_reviews, to: :channel

  def visible_in_embed?
    available? && !fake? && show_on_profile && deleted_at.nil?
  end

  def always_present_title
    title.presence || session.try(:always_present_title)
  end

  def always_present_description
    description ? description : session&.always_present_description
  end

  def organizer
    session&.organizer
  end

  def available?
    status == Statuses::DONE
  end

  # utm_params are needed for tracking visits from email links
  # @see UTM dependency
  # refc_user for sharing
  # @see SharingHelper, SharedControllerHelper
  def absolute_path(utm_params = nil, refc_user = nil)
    return nil if room.blank?

    result = room.abstract_session.absolute_path
    params = ["video_id=#{id}"]
    params << utm_params if utm_params
    params << "refc=#{refc_user.my_referral_code_text}" if refc_user.is_a?(User)
    result += "?#{params.join('&')}"
    result
  end

  def relative_path
    "#{room.abstract_session.relative_path}?video_id=#{id}"
  rescue StandardError => e
    Airbrake.notify(e.message,
                    parameters: {
                      video_id: id
                    })
    nil
  end

  def mark_as_destroy
    touch(:deleted_at)
  end

  def self.with_new_vods
    not_fake.joins(:session)
            .where.not(sessions: { recorded_purchase_price: nil })
            .where(rooms: { vod_is_fully_ready: true })
            .where(sessions: { private: false, age_restrictions: 0, fake: false })
            .where(videos: { status: Video::Statuses::DONE, show_on_profile: true })
  end

  def self.for_sessions(session_ids)
    not_fake.joins(:session)
            .where.not(sessions: { recorded_purchase_price: nil })
            .where(sessions: { private: false, age_restrictions: 0, fake: false })
            .where(sessions: { id: session_ids })
            .where(videos: { status: Video::Statuses::DONE, show_on_profile: true })
            .order('sessions.start_at desc').preload(:session)
  end

  def self.for_channel(channel_id)
    not_fake.joins(:session)
            .where.not(sessions: { recorded_purchase_price: nil })
            .where(sessions: { private: false, age_restrictions: 0, fake: false })
            .where(sessions: { channel_id: channel_id })
            .where(videos: { status: Video::Statuses::DONE, show_on_profile: true })
            .order('sessions.start_at desc').preload(:session)
  end

  def self.for_channel_and_user(channel_id, uid)
    user = User.find_by(id: uid)
    age = begin
      user.get_age_restrictions
    rescue StandardError
      0
    end
    channel_query = { fake: false, status: :approved }
    channel_query[:id] = channel_id if channel_id
    uid ||= -1
    pid = begin
      user.presenter.id
    rescue StandardError
      -1
    end
    qu = <<~EOL
      videos.id IN (
        SELECT videos.id FROM videos
               INNER JOIN rooms ON rooms.id = videos.room_id AND rooms.abstract_session_type = 'Session'
               INNER JOIN sessions ON sessions.id = rooms.abstract_session_id
               INNER JOIN recorded_members ON recorded_members.abstract_session_id = sessions.id AND recorded_members.abstract_session_type = 'Session'
               INNER JOIN participants ON participants.id = recorded_members.participant_id
               WHERE participants.user_id = :user_id AND sessions.recorded_purchase_price IS NOT NULL
      UNION
        SELECT videos.id FROM videos
               INNER JOIN rooms ON rooms.id = videos.room_id AND rooms.abstract_session_type = 'Session'
               INNER JOIN sessions ON sessions.id = rooms.abstract_session_id
               WHERE sessions.private IS FALSE
               AND sessions.age_restrictions <= :age AND sessions.recorded_purchase_price IS NOT NULL
      UNION
        SELECT videos.id FROM videos
               INNER JOIN rooms ON rooms.id = videos.room_id AND rooms.abstract_session_type = 'Session'
               INNER JOIN sessions ON sessions.id = rooms.abstract_session_id
               WHERE sessions.presenter_id = :presenter_id AND sessions.recorded_purchase_price IS NOT NULL
      )
    EOL
    available.joins(session: %i[channel user]).
      # where(show_on_profile: true, fake: false, sessions: {fake: false}, users: {fake: false}). #FIXME return back fake: false in query after remove page https://unite.live/demo-marketplace/fashion_rocks
      where(show_on_profile: true, sessions: { fake: false }, users: { fake: false })
             .where(rooms: { vod_is_fully_ready: true }, channels: channel_query)
             .where('channels.listed_at IS NOT NULL').where(qu, user_id: uid, presenter_id: pid, age: age).preload(:session)
  end

  def self.with_featured_vods(limit = 10)
    not_fake.joins(:session)
            .where.not(sessions: { recorded_purchase_price: nil })
            .where(videos: { status: Video::Statuses::DONE, featured: true })
            .order('sessions.start_at desc').preload(:session).limit(limit)
  end

  def publish!
    if status == 'done'
      update_attribute(:published, Time.now) if published.blank?
    else
      update(status: 'ready_to_tr', published: Time.now)
    end
  end

  def unpublish!
    update_attribute(:published, nil)
  end

  def published?
    !!published
  end

  def rating
    session&.average ? session.average.avg : 0
  end

  def s3_domain
    # link to Immerss bucket in case when record is copied from Immerss
    old_id.present? ? ENV['S3_IMMERSS_DOMAIN'] : ENV['HWCDN']
  end

  def s3_path
    # taking old_id of room in case when record is copied from Immerss
    room_id = old_id.present? ? (room.try(:old_id) || self.room_id) : self.room_id
    "/#{user_id}/#{room_id}"
  end

  def original_url
    if Rails.env.development?
      '/stub/stream.mp4'
    elsif original_name.present?
      "https://#{s3_domain}#{s3_path}/#{original_name}"
    elsif filename.present?
      "https://#{s3_domain}#{s3_path}/#{filename}"
    end
  end

  def original_path
    if Rails.env.development?
      'stub/stream.mp4'
    elsif original_name.present?
      "#{s3_path}/#{original_name}".gsub(%r{^/}, '')
    elsif filename.present?
      "#{s3_path}/#{filename}".gsub(%r{^/}, '')
    end
  end

  def url
    if hls_main
      "https://#{ENV['HWCDN']}#{hls_main}"
    elsif Rails.env.development?
      '/stub/stream.mp4'
    else
      "https://#{ENV['HWCDN']}/#{user_id}/#{room_id}/#{filename}"
    end
  end

  def preview_url
    if hls_preview
      "https://#{ENV['HWCDN']}#{hls_preview}"
    elsif preview_filename.present?
      "https://#{ENV['HWCDN']}/#{user_id}/#{room_id}/#{preview_filename}"
    elsif Rails.env.development?
      '/stub/preview_stream.mp4'
    else
      url
    end
  end

  def image_by_size(size)
    "https://#{ENV['HWCDN']}#{hls_preview_path}images/#{main_image_number}/#{size.delete('x')}.jpg"
  end

  def poster_url
    return session.pinterest_share_preview_image_url if Rails.env.test?

    if video_image&.image&.player&.url
      video_image.image.player.url
    elsif hls_main
      image_by_size('410x230')
    elsif Rails.env.development?
      "/stub/jpgs/#{id.to_s[-1]}.jpg"
    elsif preview_filename || filename
      "https://#{ENV['HWCDN']}/#{user_id}/#{room_id}/#{preview_filename || filename}.jpg"
    end
  end

  alias_method :pinterest_share_preview_image_url, :poster_url
  alias_method :share_image_url, :poster_url

  def share_title
    organizer_display_name = (user&.public_display_name || organizer&.public_display_name).to_s
    I18n.t('models.video.share_title', organizer_display_name: organizer_display_name, title: always_present_title)
  end

  def share_description
    always_present_description
  end

  def duration_in_minutes
    duration.to_i / 1000 / 60 if duration.present? && duration.to_i.positive?
  end

  def actual_duration
    cropped_duration.to_i.zero? ? duration.to_i : cropped_duration
  end

  def should_index?
    session.present?
  end

  def is_fake?
    fake? || (session.present? && session.is_fake?)
  end

  def multisearch_reindex
    if Rails.env.test?
      begin
        update(solr_updated_at: updated_at)
      rescue Errno::ECONNREFUSED => e
        Rails.logger.warn e.message
      end
    else
      IndexVideo.perform_async(id)
    end
  end

  def sanitize_description
    self.description = Sanitize.clean(description.to_s.html_safe,
                                      elements: %w[a b i br s u ul ol li p strong em],
                                      attributes: { a: %w[href target title] }.with_indifferent_access)
  end

  def total_views_count
    views_count + session&.views_count.to_i
  end

  def total_unique_views_count
    unique_views_count.to_i + session&.unique_views_count.to_i
  end

  def unique_view_group_start_at
    Time.now.utc.beginning_of_hour
  end

  def raters_count
    @raters_count ||= session&.raters_count || 0
  end

  def start_at
    @start_at ||= ffmpegservice_starts_at.present? ? DateTime.parse(ffmpegservice_starts_at) : (room.became_active_at || room.actual_start_at)
  end

  def cropped_start_at
    @cropped_start_at ||= start_at + crop_seconds.to_i.seconds
  end

  private

  def set_default_title
    return unless room

    update(title: session.always_present_title)
  end

  def set_default_description
    return unless room

    update(description: session&.always_present_description)
  end

  def validate_status_ready_to_tr
    return true unless status_changed? && status == Statuses::READY_TO_TR

    unless status_was.in?([
                            Statuses::TRANSCODING, Statuses::DONE, Statuses::ORIGINAL_VERIFIED, Statuses::ERROR
                          ])
      errors.add(:status,
                 'The video is not ready to be transcoded. Please contact the administrator.')
    end
  end

  def status_changed_callbacks
    check_storage_records
    notify_session_video_published
    notify_video_ready_to_transcode
  end

  def check_storage_records
    VideoJobs::VodStorage::CheckStorageRecordsJob.perform_async(id)
  end

  def notify_session_video_published
    if status_done? && published? && session.present?
      SessionsChannel.broadcast_to session,
                                   event: 'new_video_published',
                                   data: { video: {
                                     id: id,
                                     relative_path: relative_path
                                   } }
    end
  end

  def notify_video_ready_to_transcode
    return unless status_original_verified?
    return unless session&.do_record?

    VideoMailer.uploaded(id).deliver_later
  end
end
