# frozen_string_literal: true

ActiveAdmin.register SignupToken do
  menu parent: 'Admin settings'

  actions :all, except: %i[new]

  scope(:all)
  scope(:usable, &:usable)
  scope(:used, &:used)
  scope(:not_used, &:not_used)

  filter :id
  filter :user_id
  filter :token
  filter :can_use_wizard
  filter :can_buy_subscription
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :usable do |signup_token|
      if signup_token.usable?
        status_tag('green', label: 'YES')
      else
        status_tag('red', label: signup_token.used? ? 'USED' : 'EXPIRED')
      end
    end
    column :token do |signup_token|
      link_to signup_token.token, root_url(signup_token: signup_token.token)
    end
    column :wizard, &:can_use_wizard
    column :subscription, &:can_buy_subscription
    column :user, sortable: :user_id
    column :organization
    column :used_at, sortable: :used_at
    column :created_at

    actions
  end

  form do |f|
    f.inputs do
      f.input :can_use_wizard
      f.input :can_buy_subscription
    end

    f.actions
  end

  show do
    attributes_table do
      row :url do |signup_token|
        url = root_url(signup_token: signup_token.token)
        link_to url, url
      end
      (resource.attributes.keys - %w[token used_at created_at updated_at]).each do |attr|
        row attr
      end
      row :user
      row :organization, &:organization
      row :usable, &:usable?
      row :expired, &:expired?
      row :used, &:used?
      row :used_at
      row :created_at
      row :updated_at
    end
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end

  action_item :create_token, only: [:index] do
    link_to('New token', create_token_service_admin_panel_signup_tokens_path, target: '_blank', class: 'member_link', rel: 'noopener')
  end

  collection_action :create_token, method: [:get] do
    signup_token = SignupToken.create
    redirect_to service_admin_panel_signup_token_path(signup_token)
  end
end
