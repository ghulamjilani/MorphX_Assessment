# frozen_string_literal: true

ActiveAdmin.register LinkPreview do
  menu parent: 'Blog'

  filter :id
  filter :url
  filter :status, as: :select, collection: proc { LinkPreview::Statuses::ALL }
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :url do |res|
      link_to "#{res.url.to_s.first(50)}#{'...' if res.url.to_s.length > 50}", res.url
    end
    column :title do |res|
      "#{res.title.to_s.first(30)}#{'...' if res.title.to_s.length > 30}"
    end
    column :description do |res|
      "#{res.description.to_s.first(30)}#{'...' if res.description.to_s.length > 30}"
    end
    column :status
    column :created_at
    column :updated_at
    column 'Parse' do |object|
      raw(link_to('Parse', parse_service_admin_panel_link_preview_path(object), target: '_blank'.to_s))
    end

    actions
  end

  form do |f|
    f.inputs do
      f.input :url
      f.input :title
      f.input :description
      f.input :image_url
      f.input :status, as: :select, collection: LinkPreview::Statuses::ALL
    end
    f.actions
  end

  actions :all

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end

  member_action :parse, method: :get do
    LinkPreviewJobs::ParseJob.new.perform(resource.id)
    flash[:success] = 'Parse job performed.'
    redirect_back fallback_location: service_admin_panel_link_previews_path
  end

  action_item :switch_transcode, only: %i[edit show] do
    link_to 'Parse URL', parse_service_admin_panel_link_preview_path(resource)
  end
end
