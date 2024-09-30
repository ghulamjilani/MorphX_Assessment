# frozen_string_literal: true

class Webhook::V1::QencodeController < ActionController::Base
  skip_before_action :verify_authenticity_token

  # Parameters: {"status"=>"{\"status\": \"queued\", \"images\": [], \"error_description\": null, \"videos\": [], \"error\": 0}", "task_token"=>"d48279d04ead11e8b730aa831f35b3f7", "event"=>"queued", "payload"=>"100500"}
  # Parameters: {"status"=>"{\"status\": \"completed\", \"images\": [{\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-0-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/19201080.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/19201080.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-1-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/10560.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/10560.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-2-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/920500.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/920500.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-3-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/410230.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/410230.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-4-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/19201080.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/19201080.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-5-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/10560.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/10560.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-6-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/920500.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/920500.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-7-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/410230.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/410230.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-8-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/920500.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/920500.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-9-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/410230.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/410230.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-10-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/19201080.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/19201080.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-11-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/10560.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/10560.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-12-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/410230.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/410230.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-13-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/920500.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/920500.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-14-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/19201080.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/19201080.jpg\", \"format\": null}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"image-15-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/images/10560.jpg\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/images/10560.jpg\", \"format\": null}}], \"error_description\": null, \"videos\": [{\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"video-0-0\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/hls//playlist.m3u8\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/hls/\", \"format\": \"hls\"}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"video-0-1\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/hls//playlist.m3u8\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/hls/\", \"format\": \"hls\"}}, {\"profile\": \"5ae870e362aa3\", \"status\": \"completed\", \"tag\": \"video-0-2\", \"error_description\": null, \"error\": 0, \"url\": \"https://immerss-assets-develop.s3.amazonaws.com/a22cb3784eae11e88f5ed66ff13caf24/hls//playlist.m3u8\", \"storage\": {\"type\": \"amazon_s3\", \"bucket\": \"immerss-assets-develop\", \"key\": \"/a22cb3784eae11e88f5ed66ff13caf24/hls/\", \"format\": \"hls\"}}], \"error\": 0}", "task_token"=>"a7d00e924eae11e8bac7aa831f35b3f7", "event"=>"saved", "payload"=>"100500"}
  # JSON.parse = {"status"=>"completed", "images"=>[
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-0-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/19201080.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/19201080.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-1-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/10560.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/10560.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-2-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/920500.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/920500.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-3-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/410230.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/410230.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-4-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/19201080.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/19201080.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-5-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/10560.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/10560.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-6-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/920500.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/920500.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-7-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/410230.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/410230.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-8-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/920500.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/920500.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-9-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/410230.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/410230.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-10-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/19201080.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/19201080.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-11-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/10560.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/10560.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-12-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/410230.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/410230.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-13-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/920500.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/920500.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-14-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/19201080.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/19201080.jpg", "format"=>nil}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"image-15-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/images/10560.jpg", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/images/10560.jpg", "format"=>nil}}],
  # "error_description"=>nil, "videos"=>[
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"video-0-0", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/hls//playlist.m3u8", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/hls/", "format"=>"hls"}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"video-0-1", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/hls//playlist.m3u8", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/hls/", "format"=>"hls"}},
  # {"profile"=>"5ae870e362aa3", "status"=>"completed", "tag"=>"video-0-2", "error_description"=>nil, "error"=>0, "url"=>"https://immerss-assets-develop.s3.amazonaws.com/740a52004eb011e89a993eaaacfc0f55/hls//playlist.m3u8", "storage"=>{"type"=>"amazon_s3", "bucket"=>"immerss-assets-develop", "key"=>"/740a52004eb011e89a993eaaacfc0f55/hls/", "format"=>"hls"}}], "error"=>0}
  def video
    status = JSON.parse(params[:status])
    if (transcode_task = TranscodeTask.find_by(job_id: params[:task_token]))
      transcode_task.update(
        status: status['status'],
        percent: status['percent'],
        error: status['error'],
        error_description: status['error_description']
      )
    elsif (video = Video.find(params[:payload]))
      if params[:event] == 'saved' && status['error'].to_i.zero?
        video.update_columns(status: Video::Statuses::TRANSCODED, error_reason: nil)
        video.room.update_column(:vod_is_fully_ready, true)
      elsif params[:event] == 'error' || status['error'].to_i == 1
        if video.error_reason.blank?
          video.update_columns(status: Video::Statuses::READY_TO_TR, error_reason: 'transcode_error1')
        else
          Airbrake.notify('Qencode: raise error', parameters: params)
          video.update_columns(status: Video::Statuses::ERROR, error_reason: 'transcode_error2')
        end
      end
    else
      Airbrake.notify("Qencode: Can't find Video", parameters: params)
    end

    head :ok
  rescue StandardError => e
    Airbrake.notify(e, parameters: params)
    head :ok
  end

  def recording
    status = JSON.parse(params[:status])
    if (transcode_task = TranscodeTask.find_by(job_id: params[:task_token]))
      transcode_task.update(
        status: status['status'],
        percent: status['percent'],
        error: status['error'],
        error_description: status['error_description']
      )
    elsif (video = Recording.find_by(id: params[:payload]))
      if params[:event] == 'saved' && status['error'].to_i.zero?
        video.update_column(:status, :transcoded)
      elsif params[:event] == 'error' || status['error'].to_i == 1
        if video.error_reason.blank?
          video.update_columns(status: :ready_to_tr, error_reason: 'transcode_error1')
        else
          video.update_columns(status: :error, error_reason: 'transcode_error2')
        end
        Airbrake.notify('Qencode: raise error', parameters: params)
      end
    else
      Airbrake.notify("Qencode: Can't find Recording", parameters: params)
    end

    head :ok
  rescue StandardError => e
    Airbrake.notify(e, parameters: params)
    head :ok
  end
end
