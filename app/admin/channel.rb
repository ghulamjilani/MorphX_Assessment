# frozen_string_literal: true

ActiveAdmin.register Channel do
  menu parent: 'System'

  batch_action :recreate_short_url do |ids|
    models = Channel.where(id: ids)
    models.each(&:recreate_short_urls)

    redirect_to collection_path, alert: 'Short urls will be recreated soon'
  end

  batch_action :update_short_url do |ids|
    models = Channel.where(id: ids)
    models.each(&:update_short_urls)

    redirect_to collection_path, alert: 'Short urls will be updated soon'
  end

  member_action :approve_channel, method: :get do
    resource.update(status: Channel::Statuses::APPROVED)
    redirect_back fallback_location: collection_path, notice: "Channel ##{resource.id} approved!"
  end

  action_item :approve_channel, only: :show do
    if resource.pending_review?
      (link_to 'Approve', approve_channel_service_admin_panel_channel_path(resource),
               data: { confirm: 'Are you sure?' })
    end
  end

  member_action :refresh_slug, method: :put do
    resource.update(slug: nil)
    redirect_to resource_path, notice: 'Slug updated!'
  end

  action_item :refresh_slug, only: :show do
    link_to 'Refresh slug', refresh_slug_service_admin_panel_channel_path(resource), method: :put
  end

  action_item :create_sub, only: :show do
    link_to 'Create Free Subscription',
            new_service_admin_panel_free_subscription_path(free_subscription: { channel_id: resource.id }), method: :get
  end

  batch_action :show_on_home do |ids|
    collection.where(id: ids).update_all(show_on_home: true, hide_on_home: false)
    redirect_to collection_path, alert: 'Channels updated'
  end

  batch_action :hide_on_home do |ids|
    collection.where(id: ids).update_all(show_on_home: false, hide_on_home: true)
    redirect_to collection_path, alert: 'Channels updated'
  end

  batch_action :mark_as_fake do |ids|
    collection.where(id: ids).update_all(fake: true)
    redirect_to collection_path, alert: 'Channels updated'
  end

  member_action :unarchive, method: :put do
    resource.update(archived_at: nil)
    redirect_to resource_path, notice: 'Unarchived!'
  end

  action_item :unarchive, only: :show do
    link_to 'Unarchive', unarchive_service_admin_panel_channel_path(resource), method: :put if resource.archived?
  end

  member_action :set_default, method: :put do
    Channel.transaction do
      resource.organization.channels.update_all(is_default: false)
      resource.update!(is_default: true)
    end
    redirect_to resource_path, notice: 'Channel is default now!'
  end

  action_item :set_as_default, only: :show do
    link_to 'Set as default', set_default_service_admin_panel_channel_path(resource), method: :put
  end

  before_action do
    Channel.class_eval do
      def listed
        !!listed_at
      end

      def listed=(val)
        case val
        when '0'
          self.listed_at = nil
        when '1'
          self.listed_at = Time.now
        else
          raise ArgumentError, val.to_s
        end
      end

      def to_param
        id.to_s
      end
    end
  end
  actions :all, except: %i[new create destroy]

  filter :id
  filter :title
  filter :slug
  filter :category
  filter :organization_id, label: 'Organization ID'
  filter :organization_name_cont, label: 'Organization name'
  filter :organization_user_id_eq, label: 'User ID'
  filter :organization_user_email_cont, as: :string, label: 'User email'
  filter :organization_user_display_name_cont, as: :string, label: 'User name'
  filter :is_default
  filter :fake, as: :check_boxes, collection: [['Yes', true], ['No', false]], if: proc { !current_admin.platform_admin? }
  filter :show_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :hide_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :autoshow_sessions_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :display_in_coming_soon_section, as: :check_boxes, collection: [['Yes', true], ['No', false]],
                                          label: 'Display in brand section'
  filter :status, as: :select, collection: proc { Channel::Statuses::ALL }
  filter :channel_type_description, as: :select, collection: proc { ChannelType.pluck(:description) }
  # filter :promo_start
  # filter :promo_end
  filter :promo_weight
  filter :short_url
  filter :stripe_id
  filter :im_conversation_enabled
  filter :show_documents

  csv do
    column(:id)
    column(:organization_id) { |o| o.organization.try(:id) }
    column(:organization_name) { |o| o.organization.try(:name) }
    column(:user_id) { |o| o.user.try(:id) }
    column(:user_name) { |o| o.user.try(:public_display_name) }
    column(:presenter_email) { |o| o.user.try(:email) }
    column(:category) { |o| o.category.name }
    column(:channel_type) { |o| o.channel_type.description }
    column(:status)
    column(:title)
    column(:description)
    column(:channel_location)
    column(:approximate_start_date)
    column(:rejection_reason)
    column(:listed_at)
    column(:list_automatically_after_approved_by_admin)
    column(:shares_count)
    column(:archived_at)
    column(:slug)
    column(:fake) unless current_admin.platform_admin?
    column(:show_on_home)
    column(:hide_on_home)
    column(:autoshow_sessions_on_home)
    column(:created_at)
    column(:updated_at)
    column(:promo_start)
    column(:promo_end)
  end

  index do
    selectable_column
    column :id
    column :title
    column :organization
    column 'User' do |obj|
      link_to obj.organization.user.display_name, service_admin_panel_user_path(obj.organization.user)
    end
    column :show_on_home
    column :hide_on_home
    column :autoshow_sessions_on_home
    column :status
    column :listed_at
    column :category
    column :channel_type
    column :is_default
    column :promo_weight
    column :views_count
    column :unique_views_count
    column :short_url
    column :fake
    column :created_at
    actions defaults: true, confirm: 'Are you sure?' do |channel|
      if channel.pending_review?
        "<br>#{link_to 'Approve', approve_channel_service_admin_panel_channel_path(channel),
                       data: { confirm: 'Are you sure?' }, class: 'member_link'}"
          .html_safe
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :title
      f.input :description, as: :text, input_html: { rows: 6 }
      # f.input :display_in_coming_soon_section, label: 'Display in brand section'
      # f.input :brand_weight
      f.input :status, as: :select, hint: 'Add reject reason if status rejected', collection: [
        Channel::Statuses::DRAFT,
        Channel::Statuses::PENDING_REVIEW,
        Channel::Statuses::APPROVED,
        Channel::Statuses::REJECTED
      ]
      f.input :rejection_reason
      f.input :autoshow_sessions_on_home
      f.input :live_guide_is_visible, as: :boolean
      f.input :listed, as: :boolean
      f.input :featured, as: :boolean
      f.input :fake unless current_admin.platform_admin?
      f.input :show_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :hide_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :slug
      f.input :category
      f.input :promo_weight
      # f.input :stripe_id, label: 'Stripe Product ID'
      # f.input :commercials_url
      # f.input :commercials_duration
      # f.input :commercials_mime_type
      f.input :im_conversation_enabled
      f.input :show_documents
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :uuid
      row :organization
      row :organization_id
      row 'User' do |obj|
        link_to obj.organization.user.display_name, service_admin_panel_user_path(obj.organization.user)
      end
      row :user_id do |obj|
        obj.user.id
      end
      row :category
      row :channel_type
      (resource.attributes.keys - %w[id uuid organization_id presenter_id category_id channel_type_id created_at updated_at fake]).each do |attr|
        row attr
      end
      row :fake unless current_admin.platform_admin?
      row :created_at
      row :updated_at
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

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end

    def scoped_collection
      if current_admin.platform_admin?
        super.joins(organization: :user).where(fake: false, organizations: { fake: false }, users: { fake: false })
      else
        super
      end
    end
  end
end
