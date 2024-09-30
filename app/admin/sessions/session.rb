# frozen_string_literal: true

ActiveAdmin.register Session do
  menu parent: 'Sessions'

  # form partial: 'form'
  before_action do
    Session.class_eval do
      def to_param
        id.to_s
      end
    end
  end
  remove_filter :min_number_of_immersive_and_livestream_participants

  scope(:all, default: true)
  scope(:upcoming) { |scope| scope.upcoming.not_cancelled }
  scope(:active) do |scope|
    scope.joins(:room).where(':time_now BETWEEN actual_start_at::timestamp AND actual_end_at::timestamp',
                             { time_now: Time.zone.now })
  end
  scope(:pending_approval) do |scope|
    scope.upcoming.not_cancelled.not_stopped.where(status: Session::Statuses::REQUESTED_FREE_SESSION_PENDING)
  end
  scope(:paid) do |scope|
    scope.where('sessions.immersive_purchase_price > 0 OR sessions.livestream_purchase_price > 0')
  end
  scope(:free) do |scope|
    scope.where('sessions.immersive_purchase_price = 0 OR sessions.livestream_purchase_price = 0')
  end
  scope('Interactive Paid', :immersive_paid) { |scope| scope.where('sessions.immersive_purchase_price > 0') }
  scope(:livestream_paid) { |scope| scope.where('sessions.livestream_purchase_price > 0') }
  scope(:replay_paid) { |scope| scope.where('sessions.recorded_purchase_price > 0') }
  scope('Interactive Free', :immersive_free) { |scope| scope.where('sessions.immersive_purchase_price = 0') }
  scope(:livestream_free) { |scope| scope.where('sessions.livestream_purchase_price = 0') }
  scope(:replay_free) { |scope| scope.where('sessions.recorded_purchase_price = 0') }
  scope(:show_on_home) { |scope| scope.where(show_on_home: true) }
  scope(:hide_on_home) { |scope| scope.where(hide_on_home: true) }
  scope(:blocked, &:blocked)

  batch_action :recreate_short_url do |ids|
    models = Session.where(id: ids)
    models.each(&:recreate_short_urls)

    redirect_to collection_path, alert: 'Short urls will be recreated soon'
  end

  batch_action :update_short_url do |ids|
    models = Session.where(id: ids)
    models.each(&:update_short_urls)

    redirect_to collection_path, alert: 'Short urls will be updated soon'
  end

  batch_action :cancel, confirm: 'Are you sure?' do |ids|
    reason = AbstractSessionCancelReason.find_or_create_by(name: 'Technical difficulties')
    messages = []
    batch_action_collection.find(ids).each do |obj|
      interactor = SessionCancellation.new(obj, reason)
      unless interactor.execute
        messages << "ID:#{obj.id} #{obj.errors.full_messages}"
      end
    end
    messages << 'Success' if messages.blank?
    redirect_to collection_path, alert: messages.join('\n')
  end

  batch_action :show_on_home do |ids|
    Session.where(id: ids).update_all(show_on_home: true, hide_on_home: false)
    redirect_to collection_path, alert: 'Sessions updated'
  end

  batch_action :hide_on_home do |ids|
    Session.where(id: ids).update_all(show_on_home: false, hide_on_home: true)
    redirect_to collection_path, alert: 'Sessions updated'
  end

  filter :id
  filter :presenter_user_id, label: 'User ID', as: :numeric
  filter :presenter_user_email_cont, label: 'User email', as: :string
  filter :presenter_user_display_name_cont, label: 'User name', as: :string
  filter :start_at
  filter :status, label: 'Publish Status', as: :select, collection: proc { Session::Statuses::ALL }
  filter :title
  filter :channel_title, label: 'Channel Title', as: :string
  filter :age_restrictions
  filter :private
  filter :abstract_session_cancel_reason
  filter :free_trial_for_first_time_participants
  filter :fake, as: :check_boxes, collection: [['Yes', true], ['No', false]], if: proc { !current_admin.platform_admin? }
  filter :show_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :hide_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :blocked, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :start_now
  filter :promo_weight
  filter :short_url
  filter :ffmpegservice_account_id

  index do
    selectable_column
    column :id
    column :show_on_home
    column :hide_on_home
    column :fake
    column :blocked
    column :channel
    column :room
    column 'User' do |obj|
      link_to obj.presenter.user.display_name, service_admin_panel_user_path(obj.presenter.user, session_id: obj)
    end
    column 'Publish Status', sortable: :status, &:status
    column :start_at, sortable: :start_at
    # column :start_now
    column :end_at
    column :title do |obj|
      link_to(obj.title, obj.absolute_path, target: '_blank', rel: 'noopener')
    end
    column :device_type
    column 'Interactive Price', sortable: :immersive_purchase_price, &:immersive_purchase_price
    column :livestream_price, sortable: :livestream_purchase_price, &:livestream_purchase_price
    column :replay_price, sortable: :recorded_purchase_price, &:recorded_purchase_price
    column :promo_weight
    column :short_url do |obj|
      link_to(obj.short_url)
    end
    column :ffmpegservice_account do |obj|
      if obj.ffmpegservice_account_id.present?
        link_to(obj.ffmpegservice_account_id, service_admin_panel_ffmpegservice_account_path(obj.ffmpegservice_account_id), target: '_blank', rel: 'noopener')
      end
    end
    column :views_count
    column :unique_views_count
    column :actions do |object|
      raw(%(#{link_to 'View', [:service_admin_panel, object], class: 'actions_link_in_sessino_admin'}
          #{
            unless object.status == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
              (link_to 'Edit', [:edit, :service_admin_panel, object], class: 'actions_link_in_sessino_admin')
            end}))
    end
  end

  actions :all, except: %i[new create destroy]

  action_item :start_stop, only: :show do
    wa = session.room&.ffmpegservice_account
    if wa&.sandbox
      link_to "#{wa.stream_off? ? 'Start' : 'Stop'} stream",
              switch_stream_status_service_admin_panel_session_path(session)
    end
  end

  member_action :switch_stream_status, method: :get do
    wa = resource.room&.ffmpegservice_account
    if wa&.sandbox
      flash[:success] = if wa.stream_off?
                          wa.stream_up!
                          'Stream UP!'
                        else
                          wa.stream_off!
                          'Stream OFF!'
                        end
    else
      flash[:error] = 'only for sandbox mode'
    end

    redirect_back fallback_location: service_admin_panel_sessions_path
  end

  controller do
    def permitted_params
      params.permit!
    end

    def update
      resource.attributes = permitted_params[:session]

      resource.valid?
      # # otherwise you need to rewrite a lot of validators and and skipping conditions there
      # if !resource.errors.key?(:blocked) && !resource.errors.key?(:block_reason) || !resource.errors.key?(:status) &&
      #    !resource.errors.key?(:requested_free_session_declined_with_message) &&
      #    (errors = resource.errors.full_messages.join('.'))
      #   if resource.save(validate: false)
      #     flash[:success] = "Session has been saved, but skip validations: #{errors}"
      #   else
      #     flash[:error] = resource.errors.full_messages.join('.')
      #   end
      #   redirect_to "/service_admin_panel/sessions/#{resource.id}"
      #   return
      # end

      if resource.save
        flash[:success] = 'Session has been saved'
        redirect_to "/service_admin_panel/sessions/#{resource.id}"
      else
        render :edit
      end
    end

    def find_resource
      if /\A\d+\z/.match?(params[:id])
        scoped_collection.where(id: params[:id]).first!
      else
        scoped_collection.where(slug: params[:id]).first!
      end
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end

    def scoped_collection
      if current_admin.platform_admin?
        super.joins(presenter: :user, channel: :organization)
             .where(fake: false, users: { fake: false }, channels: { fake: false }, organizations: { fake: false })
      else
        super
      end
    end
  end

  show do
    attributes_table do
      row :id
      row :room
      row :channel
      row 'User' do
        link_to resource.presenter.user.public_display_name, service_admin_panel_user_path(resource.presenter.user_id)
      end
      row :organization
      row :url do
        link_to resource.absolute_path, resource.absolute_path
      end
      row :ffmpegservice_account_id
      row :ffmpegservice_account
      row :duration do
        "#{resource.duration}m"
      end
      row :pre_time do
        "#{resource.pre_time}m"
      end
      row :start_at
      row :stopped_at
      row :former_start_at
      (resource.attributes.keys - %w[id channel_id start_at former_start_at stopped_at pre_time duration created_at updated_at ffmpegservice_account_id fake cover crop_x crop_y crop_w crop_h rotate]).sort.each do |attr|
        row attr
      end
      row :fake
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :title
      f.input :immersive_purchase_price, hint: 'Be careful with costs modification! Think twice before updating it, enter only valid amounts.'
      f.input :immersive_free_slots
      f.input :livestream_purchase_price, hint: 'Be careful with costs modification! Think twice before updating it, enter only valid amounts.'
      f.input :livestream_free_slots
      f.input :duration, as: :select, collection: (15..600).step(5).to_a
      f.input :promo_weight, hint: 'Promo weight 100 will be first, -100 last'
      f.input :autostart
      f.input :featured
      f.input :fake unless current_admin.platform_admin?
      f.input :show_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :hide_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :blocked, as: :radio, hint: 'Add block reason if blocked'
      f.input :block_reason, as: :text, input_html: { rows: 6 }
      f.input :status, as: :select, hint: 'Add reject reason if status rejected', collection: [
        ::Session::Statuses::UNPUBLISHED,
        ::Session::Statuses::PUBLISHED,
        ::Session::Statuses::REQUESTED_FREE_SESSION_PENDING,
        ::Session::Statuses::REQUESTED_FREE_SESSION_APPROVED,
        ::Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
      ]
      f.input :requested_free_session_declined_with_message, label: 'Reject Reason'
    end
    f.actions
  end
end
