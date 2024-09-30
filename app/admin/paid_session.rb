# frozen_string_literal: true

ActiveAdmin.register Session, as: 'PaidSession' do
  menu parent: 'Ledger'
  actions :all, except: %i[new create edit update destroy]

  before_action do
    Session.class_eval do
      def to_param
        id.to_s
      end
    end
  end

  scope(:paid, default: true) do |scope|
    scope.where('sessions.immersive_purchase_price > 0 OR sessions.livestream_purchase_price > 0')
  end
  filter :presenter_user_id, label: 'User ID', as: :numeric
  filter :presenter_user_email_cont, label: 'User email', as: :string
  filter :presenter_user_display_name_cont, label: 'User name', as: :string
  filter :start_at
  filter :status, as: :select, collection: proc { Session::Statuses::ALL }
  filter :id
  filter :title
  filter :channel_title, label: 'Channel Title', as: :string
  filter :age_restrictions
  filter :private
  filter :abstract_session_cancel_reason
  filter :free_trial_for_first_time_participants
  filter :fake, as: :check_boxes, collection: [['Yes', true], ['No', false]], if: proc { !current_admin.platform_admin? }
  filter :show_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :start_now
  filter :promo_weight

  index do
    selectable_column
    column :id
    column :fake unless current_admin.platform_admin?
    column :channel
    column 'User' do |obj|
      link_to obj.presenter.user.display_name, service_admin_panel_user_path(obj.presenter.user, session_id: obj)
    end
    # column :status
    column :start_at, sortable: :start_at do |obj|
      obj.start_at.strftime('%b %d %Y, %I:%M %p %Z')
    end
    column :title
    column :device_type
    column 'Interactive Price', sortable: :immersive_purchase_price, &:immersive_purchase_price
    column :livestream_price, sortable: :livestream_purchase_price, &:livestream_purchase_price
    column :actions do |object|
      raw(%(#{link_to 'View', [:service_admin_panel, object], class: 'actions_link_in_sessino_admin'}
           #{unless object.status == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED
               (link_to 'Edit', [:edit, :service_admin_panel, object], class: 'actions_link_in_sessino_admin')
             end}))
    end
  end

  config.csv_builder = SessionCsvBuilder.new({ resource: @resource })

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
end
