# frozen_string_literal: true

ActiveAdmin.register StripeDb::Subscription, as: 'Stripe Subscriptions' do
  menu parent: 'Stripe'

  actions :all, except: %i[new create destroy]
  member_action :cancel, method: :post do
    if %w[active trialing].include?(resource.status) && resource.canceled_at.blank?
      if [true, 'true'].include?(params[:cancel_at_period_end])
        si = resource.stripe_item
        si.cancel_at_period_end = true
        si.save
        StripeDb::Subscription.create_or_update_from_stripe(resource.stripe_id)
        resource.reload
        end_of_period = DateTime.strptime(resource.stripe_item.cancel_at.to_s, '%s').in_time_zone(resource.user.timezone).strftime('%d %b %I:%M %p %Z')
        flash[:success] = "Subscription will be cancelled #{end_of_period}.\n CANCELED_AT and STATUS will be updated soon after receiving webhook, DON'T CANCEL AGAIN!!!"
      elsif [false, 'false'].include?(params[:cancel_at_period_end])
        resource.stripe_item.delete
        flash[:success] = "Subscription will be canceled immediately.\n CANCELED_AT and STATUS will be updated soon after receiving webhook, DON'T CANCEL AGAIN!!!"
      end
    end
    redirect_to resource_path(resource.id)
  end

  filter :customer, label: 'Stripe Customer ID'
  filter :stripe_id, label: 'Stripe Subscription ID'
  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :stripe_plan_id, label: 'Plan ID'
  filter :status
  filter :created_at
  filter :start_date
  filter :current_period_start
  filter :current_period_end
  filter :cancel_at
  filter :canceled_at
  filter :trial_start
  filter :trial_end

  index do
    selectable_column

    column :id
    column 'Plan' do |obj|
      link_to obj.stripe_plan&.im_name, service_admin_panel_channel_plan_path(obj.stripe_plan_id)
    end
    column :user
    column :status
    column :start_date
    column :trial_start
    column :trial_end
    column :current_period_end
    column :cancel_at

    actions
  end
  show do
    columns do
      column do
        panel 'Stripe Subscriptions Details' do
          attributes_table_for resource do
            row :stripe_id
            row :user
            row :stripe_plan
            row :customer
            row :status
            row :start_date
            row :trial_start
            row :trial_end
            row :cancel_at
            row :canceled_at
            row :current_period_start
            row :current_period_end
            row :created_at
            row :updated_at
          end
          if resource.canceled_at.blank?
            render partial: 'cancel'
          end
        end
      end
      column do
        panel 'Plan Info' do
          attributes_table_for resource.stripe_plan do
            row :id
            row 'Name' do |obj|
              link_to obj.nickname, service_admin_panel_channel_plan_path(obj)
            end
            row 'Replays', &:im_replays
            row :active
            row :amount
            row :interval
            row :interval_count
            row :trial_period_days
            row 'Stripe ID', &:stripe_id
            row :created_at
          end
        end
      end
    end
    if resource.user
      panel 'Transactions' do
        table_for resource.payment_transactions.where(purchased_item: resource.stripe_plan).order(checked_at: :desc) do
          column :id
          column :pid
          column :status
          column :amount do |obj|
            (obj.amount / 100.0).round(2)
          end
          column :tax do |obj|
            (obj.tax_cents / 100.0).round(2)
          end
          column :total_amount do |obj|
            (obj.total_amount / 100.0).round(2)
          end
          column :checked_at
          column '' do |obj|
            link_to 'View', service_admin_panel_payment_transaction_path(obj)
          end
        end
      end
    end
  end
  form do |f|
    f.inputs do
      f.input :status, as: :select, collection: %i[active trialing pending canceled]
      f.input :user, as: :select, collection: User.all.order(display_name: :asc).pluck(:display_name, :id)
      f.input :customer
    end
    f.actions
  end
  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end

    def scoped_collection
      if current_admin.platform_admin?
        super.joins(:user).where(users: { fake: false })
      else
        super
      end
    end
  end
end
