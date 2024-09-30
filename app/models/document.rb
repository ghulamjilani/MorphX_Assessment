# frozen_string_literal: true
class Document < ActiveRecord::Base
  # https://www.npmjs.com/package/mime - main mime types were taken here
  # http://help.dottoro.com/lapuadlp.php - alternative source of mime types

  # .pdf | application/pdf
  #
  # .pages | application/vnd.apple.pages
  # .key | application/vnd.apple.keynote
  # .numbers | application/vnd.apple.numbers
  #
  # .odt | application/vnd.oasis.opendocument.text
  # .ods | application/vnd.oasis.opendocument.spreadsheet
  # .odp | application/vnd.oasis.opendocument.presentation
  #
  # .doc | application/msword
  # .docx | application/vnd.openxmlformats-officedocument.wordprocessingml.document
  # .xls | application/vnd.ms-excel
  # .xlsx | application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  # .pps | application/vnd.ms-powerpoint
  # .ppsx | application/vnd.openxmlformats-officedocument.presentationml.slideshow
  # .ppt | application/vnd.ms-powerpoint
  # .pptx | application/vnd.openxmlformats-officedocument.presentationml.presentation
  #
  # .txt | text/plain
  #
  # Excluded:
  # .ai | application/postscript (alternative application/illustrator)
  # .psd | image/vnd.adobe.photoshop
  # .indd

  MAX_FILE_SIZE = 100 * 1024 * 1024 # 100 MB
  AVAILABLE_CONTENT_TYPES = %w[
    application/pdf
  ].freeze

  has_one_attached :file

  belongs_to :channel, optional: false
  has_one :organization, through: :channel
  has_one :user, through: :organization
  has_many :document_members

  validate :validate_file!

  validates :title, presence: true, length: { in: 1..256 }
  validates :description, length: { maximum: 1000 }

  after_save do
    sync_title_with_blob_filename! if saved_change_to_title?
  end

  scope :includes_file, -> { includes(file_attachment: :blob) }
  scope :archived, -> { includes(:channel).where.not(channels: { archived_at: nil }) }
  scope :not_archived, -> { includes(:channel).where(channels: { archived_at: nil }) }
  scope :visible, -> { where(hidden: false) }

  def title=(val)
    sanitized = begin
      ActiveStorage::Filename.new(val).to_s
    rescue StandardError
      nil
    end
    super(sanitized)
  end

  # getter of filename without extension
  def title
    blob_filename = file.blob.filename.base if file.attached?
    self[:title].presence || blob_filename || ''
  end

  def description
    self[:description] || ''
  end

  def free?
    purchase_price.to_f.zero?
  end

  private

  def validate_file!
    if file.attached?
      if file.blob.byte_size > MAX_FILE_SIZE
        errors.add(:file, ": #{title} - size is too large")
      elsif AVAILABLE_CONTENT_TYPES.exclude?(file.blob.content_type)
        errors.add(:file, ": #{title} - type is unsupported")
      end
    else
      errors.add(:file, 'is blank')
    end
  end

  def sync_title_with_blob_filename!
    if persisted? && self[:title].present?
      filename = "#{self[:title]}.#{file.blob.filename.extension}"
      file.blob.update!(filename: filename)
    end
  end
end
