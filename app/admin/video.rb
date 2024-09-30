# frozen_string_literal: true

ActiveAdmin.register Video do
  menu parent: 'Videos'

  actions :all, except: :destroy

  batch_action :recreate_short_url do |ids|
    models = Video.joins(:room).where(id: ids)
    models.each(&:recreate_short_urls)

    redirect_to collection_path, alert: 'Short urls will be recreated soon'
  end

  batch_action :update_short_url do |ids|
    models = Video.joins(:room).where(id: ids)
    models.each(&:update_short_urls)

    redirect_to collection_path, alert: 'Short urls will be updated soon'
  end

  batch_action :show_on_home do |ids|
    collection.where(id: ids).update_all(show_on_home: true, hide_on_home: false)
    redirect_to collection_path, alert: 'Videos updated'
  end

  batch_action :hide_on_home do |ids|
    collection.where(id: ids).update_all(show_on_home: false, hide_on_home: true)
    redirect_to collection_path, alert: 'Videos updated'
  end

  scope(:all)
  scope(:waiting_admin, &:waiting_admin)
  scope(:something_wrong, &:something_wrong)
  scope(:blocked, &:blocked)
  scope(:show_on_home) { |scope| scope.where(show_on_home: true) }
  scope(:hide_on_home) { |scope| scope.where(hide_on_home: true) }

  filter :id
  filter :title
  filter :ffmpegservice_id
  filter :ffmpegservice_transcoder_id
  filter :ffmpegservice_transcoder_name
  filter :transcoding_uptime_id
  filter :user
  filter :user_id, label: 'User ID'
  filter :room_id, label: 'Room ID'
  filter :status, as: :select, collection: proc { Video::Statuses::ALL }
  filter :show_on_profile, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :show_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :hide_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :fake, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :blocked, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :short_url
  # filter :promo_start
  # filter :promo_end
  filter :promo_weight

  index do
    selectable_column
    column :id
    column :show_on_home
    column :hide_on_home
    column :show_on_profile
    column :featured
    column :fake
    column :blocked
    column(:poster) do |o|
      img(src: o.poster_url, height: 144)
    end
    column(:video) do |o|
      video_tag(o.original_url, controls: true, autobuffer: true, width: 256, height: 144) if o.original_url
    end
    column :user, sortable: :user_id do |obj|
      obj.user ? link_to(obj.user.display_name, service_admin_panel_user_path(obj.user_id)) : obj.user_id
    end
    column :room, sortable: :room_id do |obj|
      link_to obj.room_id, service_admin_panel_room_path(obj.room_id) if obj.room_id
    end
    column :status
    column :error_reason
    column :created_at
    column :short_url
    column :ffmpegservice_reason
    column :ffmpegservice_id
    column :ffmpegservice_transcoder_id
    column :transcoding_uptime_id
    column :promo_weight
    column :views_count
    column 'views total/uniq/total_uniq' do |video|
      "#{video.total_views_count} / #{video.unique_views_count} / #{video.total_unique_views_count}"
    end
    actions do |obj|
      if [Video::Statuses::DONE, Video::Statuses::ERROR].include? obj.status
        if obj.deleted_at
          link_to 'Restore', switch_destroy_service_admin_panel_video_path(obj), data: { confirm: 'Are you sure?' }
        else
          link_to 'Delete', switch_destroy_service_admin_panel_video_path(obj), data: { confirm: 'Are you sure?' }
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :title
      f.input :blocked, as: :radio, hint: 'Add block reason if blocked'
      f.input :block_reason, as: :text, input_html: { rows: 6 }
      f.input :featured, as: :boolean
      f.input :show_on_profile, as: :boolean
      f.input :fake, as: :boolean unless current_admin.platform_admin?
      f.input :show_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :hide_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :promo_weight, hint: 'Promo weight 100 will be first, -100 last'
      f.input :status, as: :select, collection: Video::Statuses::ALL
      f.input :crop_seconds
      f.input :cropped_duration
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :video do |o|
        video_tag(o.original_url, controls: true, autobuffer: true, width: 256, height: 144) if o.original_url.present?
      end
      5.times do |i|
        row("main_image_n_#{i}".to_sym) do |o|
          if o.hls_preview.present?
            img(src: "https://#{ENV['HWCDN']}#{o.hls_preview_path}images/#{i}/410230.jpg",
                height: 144)
          end
        end
      end
      row :original_url, &:original_url
      row :m3u8_url, &:url
      row :duration
      row :size
      row :original_size
      row :filename
      row :user
      row 'user id', &:user_id
      row :room
      row 'room id', &:room_id
      row :platform_ident
      row :storage_ident
      row :created_at
      row :updated_at
      row :glacer_ident
      row :status
      row :error_reason
      row :preview_filename
      row :short_url
      row :show_on_profile
      row :featured
      row :blocked
      row :block_reason
      row :fake
      row :show_on_home
      row :shares_count
      row :deleted_at
      row :referral_short_url
      row :promo_start
      row :promo_end
      row :promo_weight
      row :ffmpegservice_id
      row :ffmpegservice_transcoder_id
      row :ffmpegservice_transcoder_name
      row :transcoding_uptime_id
      row :ffmpegservice_state
      row :ffmpegservice_reason
      row :ffmpegservice_starts_at
      row :ffmpegservice_download_url
      row :zoom_state
      row :zoom_start_at
      row :zoom_end_at
      row :zoom_download_url
      row :original_name
      row :s3_root
      row :crop_seconds
      row :cropped_duration
      row :hls_main
      row :hls_preview
      row :main_image_number
      row :title
      row :width
      row :height
      row :video_ffmpegservice_url do |o|
        if o.ffmpegservice_download_url.present?
          video_tag(o.ffmpegservice_download_url, controls: true, autobuffer: true, width: 256,
                                          height: 144)
        end
      end
      row :views_count
      row :unique_views_count
      row :total_views_count
      row :total_unique_views_count
    end
  end

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end

  action_item :allow_edit_again, only: [:show] do
    link_to 'Allow presenter trim again', allow_edit_again_service_admin_panel_video_path(resource),
            data: { confirm: 'Change status to downloaded and un-publish, right? ' }
  end

  member_action :allow_edit_again, method: :get do
    video = Video.find(params[:id])
    video.published = nil
    video.status = Video::Statuses::ORIGINAL_VERIFIED
    video.error_reason = nil
    video.crop_seconds = nil
    video.cropped_duration = nil
    flash[:success] = if video.save
                        'Success'
                      else
                        video.errors.full_messages
                      end
    redirect_back fallback_location: service_admin_panel_videos_path(video)
  end

  member_action :switch_destroy, method: :get do
    video = Video.where(status: [Video::Statuses::DONE, Video::Statuses::ERROR]).find(params[:id])
    video.update(deleted_at: (video.deleted_at ? nil : Time.now))
    flash[:success] = 'Success'
    redirect_back fallback_location: service_admin_panel_videos_path
  end
end
