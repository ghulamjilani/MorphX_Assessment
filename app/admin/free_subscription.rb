# frozen_string_literal: true

ActiveAdmin.register FreeSubscription, as: 'Free Subscriptions' do
  menu parent: 'Stripe'

  actions :all

  filter :id
  filter :free_plan_id_eq, label: 'Free Plan Id'
  filter :organization_id_eq, label: 'Organization Id'
  filter :channel_id_eq, label: 'Channel Id'
  filter :channel_title_cont, label: 'Channel title contains'
  filter :user_email, as: :string
  filter :user_id_eq, label: 'User Id'
  filter :stopped_at
  filter :created_at
  filter :updated_at

  controller do
    def scoped_collection
      end_of_association_chain.includes(:free_plan, :user)
    end
  end

  index do
    selectable_column
    column :id
    column :free_plan
    column :channel, sortable: 'channels.id'
    column :organization, sortable: 'organizations.id'
    column :user_email, sortable: 'users.email'
    column :user, sortable: :user_id
    column :replays
    column :uploads
    column :interactives
    column :livestreams
    column :documents
    column :im_channel_conversation
    column :starts_at
    column :stop_at
    column :stopped_at
    column :created_at

    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :user_email
      f.input :user_id
      f.input :free_plan_id, as: :string
      f.input :start_at, as: :datetime_picker
      f.input :end_at, as: :datetime_picker
      f.input :stopped_at, as: :datetime_picker
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row 'User' do |free_subscription|
        link_to(free_subscription.user.display_name, service_admin_panel_user_path(free_subscription.user)) if free_subscription.user.present?
      end
      row :user_id
      row 'Free Plan' do |free_subscription|
        link_to(free_subscription.free_plan.name, service_admin_panel_free_plan_path(free_subscription.free_plan)) if free_subscription.free_plan.present?
      end
      (resource.attributes.keys - %w[id user_id start_at end_at stopped_at created_at updated_at]).each do |attr|
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

  controller do
    def permitted_params
      params.permit!
    end

    def scoped_collection
      collection = end_of_association_chain.joins(channel: :user)
                                           .includes(:user, :channel, :organization, :free_plan)

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
