# frozen_string_literal: true

ActiveAdmin.register StripeDb::Plan, as: 'Channel Plans' do
  menu parent: 'Stripe'

  actions :all

  index do
    selectable_column
    id_column
    column :stripe_id
    column :nickname
    column :active
    column :amount
    column :interval_count
    column :interval
    column :product
    column :trial_period_days
    column :channel_subscription_id
    column :autorenew
    column :im_enabled
    column :created_at
    actions
  end
  form do |f|
    f.inputs do
      f.input :nickname, label: 'Plan Name', required: true
      f.input :stripe_id, label: 'Stripe ID', required: true
      f.input :product, label: 'Product Stripe ID', required: true
      f.input :channel_subscription_id, as: :number, label: 'Subscription ID', required: true
      f.input :amount, as: :number, label: 'Amount in cents', required: true
      f.input :currency, as: :select, collection: %w[usd], required: true
      f.input :autorenew, as: :boolean, required: true
      f.input :im_livestreams, label: 'Include Livestreams', as: :boolean, required: true
      f.input :im_interactives, label: 'Include Interactives', as: :boolean, required: true
      f.input :im_replays, label: 'Include Replays', as: :boolean, required: true
      f.input :im_uploads, label: 'Include Uploads', as: :boolean, required: true
      f.input :im_channel_conversation, label: 'Access to Channel Conversation', as: :boolean, required: true
      f.input :active, as: :boolean, required: true
      f.input :im_enabled, label: 'Enabled(same as active)', as: :boolean, required: true
      f.input :interval, as: :select, collection: %w[day month year], allow_blank: false, required: true
      f.input :interval_count, as: :number, max: 30, min: 0, required: true
      f.input :trial_period_days, as: :number, max: 30, min: 0, required: true
      f.input :deleted_at
      f.input :created_at
      f.input :updated_at

      f.input :im_color, as: :color
      f.input :aggregate_usage
      f.input :billing_scheme, as: :select, collection: %w[per_unit], allow_blank: false, required: true
      f.input :livemode, as: :select, collection: %w[t f], allow_blank: false, required: true
      f.input :object, as: :select, collection: %w[plan], allow_blank: false, required: true
      f.input :usage_type, as: :select, collection: %w[licensed], allow_blank: false, required: true
      f.input :im_months, as: :number
      f.input :im_name
      f.input :tiers_mode
      f.input :transform_usage
    end
    f.actions
  end
  show do
    columns do
      column do
        panel 'Plan Info' do
          attributes_table_for resource do
            row :id
            row :stripe_id
            row :object
            row :active
            row :aggregate_usage
            row :amount
            row :billing_scheme
            row :created
            row :currency
            row :interval_count
            row :interval
            row :livemode
            row :nickname
            row :product
            row :tiers_mode
            row :transform_usage
            row :trial_period_days
            row :usage_type
            row :created_at
            row :updated_at
            row :channel_subscription_id
            row :im_name
            row :im_color
            row :autorenew
            row :im_livestreams
            row :im_interactives
            row :im_replays
            row :im_uploads
            row :im_channel_conversation
            row :im_enabled
            row :deleted_at
          end
        end
      end

      column do
        panel 'Subscriptions' do
          table_for resource.stripe_subscriptions do
            column :id do |obj|
              link_to "#{obj.id} (view)", service_admin_panel_stripe_subscription_path(obj)
            end
            column 'Customer' do |obj|
              link_to(obj.customer_user.display_name, service_admin_panel_user_path(obj.customer_user))
            rescue StandardError
              nil
            end
            column :status
            column 'Stripe Plan ID', &:stripe_plan_id
            column 'Stripe ID', &:stripe_id
            column :current_period_end
            column :canceled_at
            column :created_at
          end
        end
      end
    end
  end
  controller do
    def scoped_collection
      StripeDb::Plan.where.not(channel_subscription_id: nil)
    end

    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
