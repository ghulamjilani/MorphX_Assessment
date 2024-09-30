# frozen_string_literal: true

ActiveAdmin.register InteractiveAccessToken do
  menu parent: 'Sessions'

  actions :all

  filter :id
  filter :session_id
  filter :token
  filter :individual

  scope(:individual) { |scope| scope.where(individual: true) }
  scope(:shared) { |scope| scope.where(individual: false) }

  action_item :refresh_token, only: %i[show edit] do |_object|
    link_to('Refresh Token', refresh_token_service_admin_panel_interactive_access_token_path(resource.id))
  end

  member_action :refresh_token, method: :get do
    if resource.refresh_token!
      flash[:notice] = 'Token has been refreshed'
    else
      flash[:error] = 'Token has not been refreshed'
    end

    redirect_back fallback_location: service_admin_panel_interactive_access_token_path(resource)
  end

  member_action :destroy_token, method: :delete do
    resource.destroy!
    flash[:notice] = 'Token deleted'

    redirect_back fallback_location: service_admin_panel_interactive_access_tokens_path
  end

  index do
    selectable_column
    column :id
    column :session
    column :session_id
    column :individual
    column :token
    column :control do |object|
      link_to('Refresh Token', refresh_token_service_admin_panel_interactive_access_token_path(object.id))
    end

    actions
  end

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
