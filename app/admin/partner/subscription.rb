# frozen_string_literal: true

ActiveAdmin.register Partner::Subscription, as: 'Partner Subscriptions' do
  menu parent: 'Stripe'

  actions :all

  filter :id
  filter :status, as: :select, collection: ::Partner::Subscription.statuses
  filter :organization_id_eq, label: 'Organization Id'
  filter :channel_title_cont, label: 'Channel title contains'
  filter :channel_id_eq, label: 'Channel Id'
  filter :free_subscription_id_eq, label: 'Free Subscription Id'
  filter :partner_plan_id_eq, label: 'Partner Plan Id'
  filter :foreign_customer_id_eq, label: 'Foreign Customer Id'
  filter :foreign_customer_email
  filter :foreign_subscription_id_eq, label: 'Foreign Subscription Id'
  filter :stopped_at
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :partner_plan
    column :free_plan
    column :free_subscription
    column :channel, sortable: 'channels.id'
    column :organization, sortable: 'organizations.id'
    column :user_email, sortable: 'users.email' do |partner_subscription|
      partner_subscription.user.email
    end
    column :user, sortable: :user_id
    column :replays
    column :uploads
    column :interactives
    column :livestreams
    column :documents
    column :im_channel_conversation
    column :status do |partner_subscription|
      if partner_subscription.active?
        status_tag('green', label: partner_subscription.status)
      else
        status_tag('red', label: partner_subscription.status)
      end
    end
    column :stopped_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :user
      row :user_id
      row :channel
      row :channel_id
      row :free_plan
      row :free_subscription
      row :partner_plan
      (resource.attributes.keys - %w[id user_id stopped_at created_at updated_at]).each do |attr|
        row attr
      end

      row :replays
      row :uploads
      row :livestreams
      row :interactives
      row :documents
      row :im_channel_conversation
      row :starts_at
      row :start_at
      row :end_at
      row :stopped_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :stopped_at, as: :datetime_picker
      f.input :status, as: :select, collection: Partner::Subscription.statuses.keys
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit!
    end

    def scoped_collection
      collection = end_of_association_chain.joins(channel: :user)
                                           .includes(:user, :partner_plan, :free_plan, :channel, :organization)

      return collection unless current_admin.platform_admin?

      collection.where(channels: { fake: false })
                .where(organizations: { fake: false })
                .where(users: { fake: false })
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
