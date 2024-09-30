# frozen_string_literal: true

ActiveAdmin.register Blog::PostCover do
  menu parent: 'Images'
  actions :all, except: %i[new create edit update destroy]

  member_action :recreate_versions, method: :put do
    resource.image.recreate_versions!
    redirect_to resource_path, notice: 'Tadaaaaam!'
  rescue StandardError => e
    redirect_to resource_path, notice: e.message
  end

  action_item :recreate_versions, only: :show do
    link_to 'Recreate versions', recreate_versions_service_admin_panel_blog_post_cover_path(resource), method: :put
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
