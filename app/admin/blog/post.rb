# frozen_string_literal: true

ActiveAdmin.register Blog::Post do
  menu parent: 'Blog'

  before_action do
    Blog::Post.class_eval do
      def to_param
        id.to_s
      end
    end
  end

  batch_action :recreate_short_url do |ids|
    models = Blog::Post.where(id: ids)
    models.each(&:recreate_short_urls)

    redirect_back fallback_location: collection_path, alert: 'Short urls will be recreated soon'
  end

  batch_action :update_short_url do |ids|
    models = Blog::Post.where(id: ids)
    models.each(&:update_short_urls)

    redirect_back fallback_location: collection_path, alert: 'Short urls will be updated soon'
  end

  scope(:all)
  scope(:draft, &:draft)
  scope(:published, &:published)
  scope(:hidden, &:hidden)
  scope(:archived, &:archived)
  scope(:show_on_home) { |scope| scope.where(show_on_home: true) }
  scope(:hide_on_home) { |scope| scope.where(hide_on_home: true) }

  filter :id
  filter :user_id, label: 'User ID'
  filter :channel_id, label: 'Channel ID'
  filter :organization_id, label: 'Organization ID'
  filter :title
  filter :status
  filter :comments_count
  filter :show_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :hide_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :promo_weight
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :user, sortable: :user_id
    column :user_id
    column :channel, sortable: :channel_id
    column :channel_id
    column :title do |post|
      link_to(post.title, post.absolute_path, target: '_blank')
    end
    column :body do |post|
      post.body.first 72
    end
    column :status
    column :comments_count
    column :show_on_home
    column :hide_on_home
    column :promo_weight
    column :views_count
    column :created_at
    column :updated_at

    actions
  end

  show do
    attributes_table do
      row :id
      row :user
      row :organization
      row :channel
      (resource.attributes.keys - %w[id channel_id organization_id user_id]).sort.each do |attr|
        row attr
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :user_id, label: 'User ID'
      f.input :channel_id, label: 'Channel ID'
      f.input :organization_id, label: 'Organization ID'
      f.input :title
      f.input :body
      f.input :status, as: :select, collection: Blog::Post::Statuses::ALL
      f.input :show_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :hide_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      # f.input :promo_start, as: :datepicker
      # f.input :promo_end, as: :datepicker
      f.input :promo_weight
    end
    f.actions
  end

  actions :all

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
