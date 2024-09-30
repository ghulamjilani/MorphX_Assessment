# frozen_string_literal: true

ActiveAdmin.register FreePlan, as: 'Free Plans' do
  menu parent: 'Stripe'

  actions :all

  filter :id
  filter :channel_id_eq, label: 'Channel Id'
  filter :channel_uuid_eq, label: 'Channel uuid'
  filter :channel_title_cont, label: 'Channel title contains'
  filter :organization_id_eq, label: 'Organization Id'
  filter :replays
  filter :uploads
  filter :interactives
  filter :livestreams
  filter :documents
  filter :im_channel_conversation
  filter :duration_type, as: :select, collection: ::FreePlan.duration_types
  filter :duiration_in_months
  filter :start_at
  filter :end_at
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :channel, sortable: :channel_uuid
    column :organization, sortable: 'organizations.id'
    column :name
    column :replays
    column :uploads
    column :interactives
    column :livestreams
    column :documents
    column :im_channel_conversation
    column :duration_type
    column :duration_in_months
    column :start_at
    column :end_at
    column :archived_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :channel
      row :channel_id
      row :organization
      row :organization_id
      (resource.attributes.keys - %w[id created_at updated_at]).each do |attr|
        row attr
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :name
      f.input :description
      f.input :channel_uuid, as: :string
      f.input :duration_type, as: :select, collection: ::FreePlan.duration_types.keys
      f.input :duration_in_months
      f.input :start_at, as: :datetime_picker
      f.input :end_at, as: :datetime_picker
      f.input :replays
      f.input :uploads
      f.input :interactives
      f.input :livestreams
      f.input :documents
      f.input :im_channel_conversation
      f.input :archived_at, as: :datetime_picker
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit!
    end

    def scoped_collection
      collection = end_of_association_chain.joins(channel: :user)
                                           .includes(:organization)

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
