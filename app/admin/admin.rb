# frozen_string_literal: true

ActiveAdmin.register Admin do
  menu parent: 'Admin settings'

  permit_params :email, :role, :password, :password_confirmation, :receive_admin_mailing, :receive_owner_mailing,
                :receive_manager_mailing, :receive_support_mailing, :manually_set_timezone

  scope(:all)
  scope(:superadmin, &:superadmin)
  scope(:morphx_admin, &:morphx_admin)
  scope(:platform_admin, &:platform_admin)

  index do
    selectable_column
    id_column
    column :email
    column :role
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    column :receive_admin_mailing
    column :receive_owner_mailing
    column :receive_manager_mailing
    column :receive_support_mailing
    column :manually_set_timezone
    actions
  end

  filter :email
  filter :role, as: :select, collection: %w[morphx_admin platform_admin superadmin]
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs 'Admin Details' do
      f.input :email
      f.input :role, as: :select, collection: %w[morphx_admin platform_admin superadmin]
      f.input :password
      f.input :password_confirmation
      f.input :receive_admin_mailing
      f.input :receive_owner_mailing
      f.input :receive_manager_mailing
      f.input :receive_support_mailing
      f.input :manually_set_timezone, as: :select, collection: Admin.timezone_enum
    end

    f.actions
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
