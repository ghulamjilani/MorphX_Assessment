# frozen_string_literal: true

json.id document.id
json.title document.title
json.description document.description
json.file_size document.file.byte_size
json.file_extension document.file.filename.extension
json.purchase_price document.purchase_price
json.only_ppv document.only_ppv
json.only_subscription document.only_subscription
if document.file.previewable?
  json.sm_preview_path url_for(document.file.preview(resize: '100x100'))
  json.lg_preview_path url_for(document.file.preview(resize: '1000x1000'))
end

json.channel_id document.channel_id

json.created_at document.created_at.utc.to_fs(:rfc3339)
json.updated_at document.updated_at.utc.to_fs(:rfc3339)
