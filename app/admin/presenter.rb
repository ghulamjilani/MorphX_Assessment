# frozen_string_literal: true

ActiveAdmin.register Presenter do
  menu parent: 'User'

  # TODO: Presenters logic changed so we need to review current behavior and prepare new scopes
  scope(:all, default: true, except: :destroy)
  scope(:incompleted) { |scope| scope.real.without_channels }
  scope(:completed) { |scope| scope.real.has_channels }

  actions :all, except: %i[new create destroy]

  csv do
    column :id
    column(:user_id_) { |o| o.user.id }
    column(:user_name) { |o| o.user.public_display_name }
    column(:user_email) { |o| o.user.email }
    column(:user_phone) do |o|
      o.user.user_account.phone
    rescue StandardError
      nil
    end
    column :last_seen_become_presenter_step
    column :created_at
  end

  index do
    selectable_column
    column('User ID', &:user_id)
    column(:full_name) { |o| link_to o.user.full_name, [:service_admin_panel, o.user] }
    column(:user_email) { |o| o.user.email }
    column(:user_phone) do |o|
      o.user.user_account.phone
    rescue StandardError
      nil
    end
    column('Last Step') { |o| I18n.t("activeadmin.dashboard.wizard_steps.#{o.last_seen_become_presenter_step}") if o.last_seen_become_presenter_step }
    column :featured
    column :created_at
    actions
  end

  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :last_seen_become_presenter_step, label: 'Last Step', as: :select,
                                           collection: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::OPTIONS_FOR_SELECT
  filter :featured
  filter :created_at, as: :date_range

  form do |f|
    f.inputs do
      f.input :featured
      f.input :credit_line_amount
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row 'User ID' do
        resource.user_id
      end
      row :user
      (resource.attributes.keys - %w[id user_id created_at updated_at]).each do |attr|
        row attr
      end
      row :created_at
      row :updated_at
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
end
