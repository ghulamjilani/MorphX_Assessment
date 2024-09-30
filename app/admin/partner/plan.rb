# frozen_string_literal: true

ActiveAdmin.register Partner::Plan, as: 'Partner Plans' do
  menu parent: 'Stripe'

  actions :all

  filter :id
  filter :free_plan_id_eq, label: 'Free Plan Id'
  filter :channel_title_cont, label: 'Channel title contains'
  filter :channel_id_eq, label: 'Channel Id'
  filter :organization_id_eq, label: 'Organization Id'
  filter :enabled
  filter :name
  filter :foreign_plan_id_eq, label: 'Foreign Plan Id'
  filter :foreign_plan_url, label: 'Foreign Plan Url'
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :name
    column :free_plan
    column :channel, sortable: 'channels.id'
    column :organization, sortable: 'organizations.id'
    column :enabled
    column :foreign_plan_id
    column :foreign_plan_url
    column :replays
    column :uploads
    column :livestreams
    column :interactives
    column :documents
    column :im_channel_conversation
    column :start_at
    column :end_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :channel
      row :organization
      row :free_plan

      (resource.attributes.keys - %w[id created_at updated_at]).each do |attr|
        row attr
      end

      row :replays
      row :uploads
      row :livestreams
      row :interactives
      row :documents
      row :im_channel_conversation

      row :start_at
      row :end_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :free_plan_id, as: :string
      f.input :name
      f.input :description
      f.input :enabled
      f.input :foreign_plan_id
      f.input :foreign_plan_url
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit!
    end

    def scoped_collection
      collection = end_of_association_chain.joins(channel: :user)
                                           .joins(channel: :organization)
                                           .includes(:channel, :organization)
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
