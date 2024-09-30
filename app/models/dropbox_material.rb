# frozen_string_literal: true
class DropboxMaterial < ActiveRecord::Base
  belongs_to :abstract_session, polymorphic: true

  validates :path, presence: true, uniqueness: { scope: %i[abstract_session_id abstract_session_type] }

  module FileTypes
    IMAGES  = %w[png jpeg jpg gif].freeze
    AUDIO   = %w[mp3].freeze
    VIDEO   = %w[mp4].freeze
    DOCS    = %w[xls xlsx doc docx ppt, pptx pdf txt csv].freeze

    ALL = IMAGES + AUDIO + VIDEO + DOCS
  end

  def can_download?
    file_type = File.extname(path.to_s).delete('.')
    DropboxMaterial::FileTypes::DOCS.include?(file_type)
  end
  alias_method :can_download, :can_download?

  # @return {"id"=>121, "path" => "/order week 3.doc", "mime_type" => "application/msword", "data"=>nil, "can_download"=>true}
  def as_proper_json
    as_json(except: %i[created_at updated_at abstract_session_id abstract_session_type], methods: [:can_download])
  end
end
