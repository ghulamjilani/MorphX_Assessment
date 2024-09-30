# frozen_string_literal: true

ActiveAdmin.register Recording do
  menu parent: 'Videos'

  scope(:all)
  scope(:blocked, &:blocked)
  scope(:show_on_home) { |scope| scope.where(show_on_home: true) }
  scope(:hide_on_home) { |scope| scope.where(hide_on_home: true) }
  scope(:deleted) { |scope| scope.where.not(deleted_at: nil) }

  batch_action :recreate_short_url do |ids|
    models = Recording.where(id: ids)
    models.each(&:recreate_short_urls)

    redirect_to collection_path, alert: 'Short url will be recreated soon'
  end

  batch_action :update_short_url do |ids|
    models = Recording.where(id: ids)
    models.each(&:update_short_urls)

    redirect_to collection_path, alert: 'Short url will be updated soon'
  end

  batch_action :show_on_home do |ids|
    collection.where(id: ids).update_all(show_on_home: true, hide_on_home: false)
    redirect_to collection_path, alert: 'Recordings updated'
  end

  batch_action :hide_on_home do |ids|
    collection.where(id: ids).update_all(show_on_home: false, hide_on_home: true)
    redirect_to collection_path, alert: 'Recordings updated'
  end

  actions :all, except: %i[new create]

  filter :id
  filter :title
  filter :channel
  filter :channel_id, label: 'Channel ID'
  filter :show_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :hide_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :hide, label: 'Hide on Profile', as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :status, as: :select, collection: proc { Recording.statuses }
  filter :blocked, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :error_reason
  filter :short_url
  filter :promo_weight

  index do
    selectable_column
    column :id
    column :title
    column :show_on_home
    column :hide_on_home
    column :fake
    column :blocked
    column(:preview_image) do |o|
      img(src: o.poster_url, width: 140)
    end
    column :channel
    column :short_url
    column :status
    column :error_reason
    column :promo_weight
    column :views_count
    column :unique_views_count
    actions
  end

  form do |f|
    f.inputs do
      f.input :title
      f.input :description, as: :text, input_html: { rows: 6 }
      f.input :blocked, as: :radio, hint: 'Add block reason if blocked'
      f.input :block_reason, as: :text, input_html: { rows: 6 }
      f.input :show_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :hide_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :private
      f.input :hide, label: 'Hide on Profile'
      f.input :promo_weight
      f.input :status
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      (resource.attributes.keys - %w[id created_at updated_at]).sort.each do |attr|
        row attr
      end
      row :channel
      row :source_url do
        url_for(resource.file)
      rescue StandardError
        nil
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
