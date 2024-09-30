# frozen_string_literal: true

ActiveAdmin.register User do
  menu parent: 'User'

  actions :all, except: %i[new create]

  batch_action :recreate_short_url do |ids|
    models = User.where(id: ids)
    models.update_all(short_url: nil)
    models.each(&:recreate_short_urls)

    redirect_to collection_path, alert: 'Short urls will be recreated soon'
  end

  batch_action :update_short_url do |ids|
    models = User.where(id: ids)
    models.each(&:update_short_urls)

    redirect_to collection_path, alert: 'Short urls will be updated soon'
  end

  member_action :refresh_slug, method: :put do
    resource.update(slug: nil)
    redirect_to resource_path, notice: 'Slug updated!'
  end

  member_action :sign_in_as_presenter, method: :get do
    sign_in(:user, resource)
    session = Session.find_by(id: params[:session_id])
    redirect_to session ? session.relative_path : dashboard_path
  end

  member_action :switch_transcode, method: :get do
    resource.toggle_switch_transcode
    if resource.errors.present?
      flash[:error] = resource.errors.full_messages.join('.')
    else
      flash[:success] = (resource.ffmpegservice_transcode ? 'Enabled' : 'Disabled')
    end
    redirect_back fallback_location: service_admin_panel_users_path
  end

  member_action :confirm_email, method: :put do
    # TODO: - find more reliable solution that does not depend on irrelevant validation rules
    # to solve issues like:
    # Validation failed: First name can't be blank, First name is too short (minimum is 2 characters), Last name can't be blank, Last name is too short (minimum is 2 characters), Gender can't be blank, Gender is not included in the list, Birthdate can't be blank

    begin
      user = User.find(params[:id])
      user.skip_confirmation!
      user.save(validate: false)
      flash[:success] = 'Email has been manually confirmed'
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = 'Email confirmation failed. Dev team has been notified'
      Airbrake.notify(e,
                      parameters: {
                        user_id: user.id
                      })
    end
    redirect_back fallback_location: service_admin_panel_users_path
  end

  member_action :reset_password, method: :put do
    user = User.find(params[:id])
    user.send_reset_password_instructions
    flash[:success] = 'Reset password instructions was sent'

    redirect_back fallback_location: service_admin_panel_users_path
  end

  action_item :refresh_slug, only: :show do
    link_to('Refresh slug', refresh_slug_service_admin_panel_user_path(resource), method: :put) unless current_admin.platform_admin?
  end

  action_item :confirm_email, only: :show do
    link_to('Confirm Email', confirm_email_service_admin_panel_user_path(user), method: :put) unless user.confirmed?
  end

  action_item :reset_password, only: :show do
    link_to('Reset password', reset_password_service_admin_panel_user_path(user), method: :put)
  end

  action_item :sign_in, only: :show do
    link_to('Sign in', sign_in_as_presenter_service_admin_panel_user_path(user, session_id: params[:session_id]), target: '_blank') unless current_admin.platform_admin?
  end

  action_item :switch_transcode, only: :show do
    link_to("#{user.ffmpegservice_transcode ? 'Disable' : 'Enable'} transcode", switch_transcode_service_admin_panel_user_path(user)) unless current_admin.platform_admin?
  end

  batch_action :show_on_home do |ids|
    collection.where(id: ids).update_all(show_on_home: true, hide_on_home: false)
    redirect_to collection_path, alert: 'Users updated'
  end

  batch_action :hide_on_home do |ids|
    collection.where(id: ids).update_all(show_on_home: false, hide_on_home: true)
    redirect_to collection_path, alert: 'Users updated'
  end

  batch_action :mark_as_fake do |ids|
    collection.where(id: ids).update_all(fake: true)
    redirect_to collection_path, alert: 'Users updated'
  end

  before_action do
    User.class_eval do
      def to_param
        id.to_s
      end
    end
  end

  scope(:all)
  scope(:home_page) do |scope|
    pg_search = PgSearchDocument.where(searchable_type: 'User', show_on_home: true, hide_on_home: false, fake: false).not_private
    scope.where(id: pg_search.map(&:searchable_id))
  end

  filter :invited_by_id, label: 'Invited by ID'
  filter :id
  filter :email
  filter :display_name, label: 'Name'
  filter :slug
  filter :stripe_customer_id
  filter :fake, as: :select, collection: [%w[Yes true], %w[No false]], if: proc { !current_admin.platform_admin? }
  filter :show_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :hide_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :is_confirmed, as: :select, collection: [%w[Yes yes], %w[No no]], label: 'Confirmed'
  filter :organization_owner, as: :select, collection: [%w[Yes yes], %w[No no]]
  filter :user_type, as: :select, collection: [['Regular User', :regular_user], ['Service Admin', :service_admin], ['Platform Owner', :platform_owner]]
  filter :affiliate_signature
  filter :created_at, as: :date_range
  # filter :promo_start, as: :date_range
  # filter :promo_end, as: :date_range
  filter :promo_weight
  filter :short_url
  filter :ffmpegservice_transcode
  filter :last_sign_in_ip
  filter :force_password_reset
  filter :old_email
  filter :deleted

  index do
    selectable_column
    column :id
    column :email
    column :first_name
    column :last_name
    column :display_name
    column :show_on_home
    column :hide_on_home
    column :fake
    column :deleted
    column :stripe_customer_id
    column :confirmed_at
    column :created_at
    column :invited_by
    column :slug
    column :short_url
    column :old_email
    column :promo_weight
    column :views_count
    unless current_admin.platform_admin?
      column 'Sign in' do |object|
        raw(link_to('Sign in', [:sign_in_as_presenter, :service_admin_panel, object], target: '_blank'.to_s))
      end
    end

    actions
  end

  form do |f|
    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :birthdate, as: :datepicker, datepicker_options: { max_date: Time.zone.now.to_date }
      f.input :gender, as: :select, collection: User::Genders::ALL.map(&:downcase)
      f.input :can_create_free_private_sessions_without_permission, label: 'Can create private interactive sessions without admin approval'
      f.input :can_create_sessions_with_max_duration, as: :select, collection: (15..600).step(15).to_a
      f.input :can_publish_n_free_sessions_without_admin_approval, label: 'Can publish n private interactive sessions without admin approval'
      f.input :can_use_debug_area
      f.input :can_use_barcode_area
      f.input :can_use_wizard
      f.input :can_buy_subscription
      f.input :profit_margin_percent
      f.input :current_organization_id
      # f.input :overriden_minimum_live_session_cost
      f.input :fake unless current_admin.platform_admin?
      f.input :show_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :hide_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :slug
      # f.input :promo_start, as: :datepicker
      # f.input :promo_end, as: :datepicker
      f.input :promo_weight
      f.input :ffmpegservice_transcode
      f.input :affiliate_signature
      f.input :stripe_customer_id
      # f.input :force_password_reset
      f.input :deleted, as: :boolean
      f.input :platform_role
    end
    f.actions
  end

  show do
    render 'user_details', { user: user }
    columns do
      column do
        attributes_table do
          row :id
          row :first_name
          row :last_name
          row :display_name
          (resource.attributes.keys - %w[id can_publish_n_free_sessions_without_admin_approval can_create_free_private_sessions_without_permission first_name last_name created_at updated_at authentication_token confirmation_token encrypted_password remember_token reset_password_token invitation_token fake]).each do |attr|
            row attr
          end
          row :fake unless current_admin.platform_admin?
          row 'Can create private interactive sessions without admin approval', &:can_create_free_private_sessions_without_permission
          row 'Can publish n private interactive sessions without admin approval', &:can_publish_n_free_sessions_without_admin_approval
          row :created_at
          row :updated_at
        end
      end
      column do
        panel 'Business Subscriptions' do
          table_for resource.service_subscriptions.order(created_at: :desc) do
            column :id do |ss|
              link_to ss.id, service_admin_panel_stripe_db_service_subscription_path(ss)
            end
            column :plan_package
            column :status, &:service_status
            column 'Price' do |ss|
              "#{ss.stripe_plan.formatted_price}/#{ss.stripe_plan.formatted_interval}"
            end
            column 'Start At', &:created_at
            column :current_period_end
          end
        end
        panel 'Channel Subscriptions' do
          table_for resource.channels_subscriptions.order(created_at: :desc) do
            column :id do |cs|
              link_to cs.id, service_admin_panel_stripe_subscription_path(cs)
            end
            column 'Plan' do |cs|
              link_to cs.stripe_plan.title, service_admin_panel_channel_plan_path(cs.stripe_plan)
            end
            column :status
            column 'Price' do |cs|
              "#{cs.stripe_plan.formatted_price}/#{cs.stripe_plan.period}"
            end
            column 'Start At', &:created_at
            column :current_period_end
          end
        end
      end
    end
  end

  controller do
    def permitted_params
      params.permit!
    end

    def find_resource
      if /\A\d+\z/.match?(params[:id])
        scoped_collection.where(id: params[:id]).first!
      else
        scoped_collection.where(slug: params[:id]).first!
      end
    end

    def action_methods
      if Rails.env.production? && current_admin.try(:email) != 'awilner@unite.live'
        super - ['destroy']
      else
        super
      end
    end

    def update
      @user = User.find(params[:id])

      @user.attributes = permitted_params[:user]
      if @user.save
        flash[:success] = 'User successfully updated'
      else
        flash[:info] = @user.errors.full_messages.join('. ')
        @user.save(validate: false)
      end

      redirect_to edit_resource_path(@user)
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end

    def scoped_collection
      if current_admin.platform_admin?
        super.where(fake: false)
      else
        super
      end
    end
  end
end
