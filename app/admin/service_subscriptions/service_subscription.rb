# frozen_string_literal: true

ActiveAdmin.register StripeDb::ServiceSubscription do
  menu parent: I18n.t('activeadmin.stripe_db.menu')

  actions :all, except: %i[new destroy]

  member_action :upgrade, method: %i[get post] do
    if request.post?
      plan = StripeDb::ServicePlan.joins(:plan_package).active.where(%(plan_packages.active = TRUE)).find(params[:plan_id])
      begin
        resource.change_plan!(plan.id)
        redirect_to resource_path, notice: 'Request of Service Subscription Plan Upgrade created! Please reload the page in several minutes.'
      rescue StandardError => e
        flash[:error] = if e.message.include?('no attached payment source')
                          'User must add payment method to enable business plan change'
                        else
                          e.message
                        end
        @available_plans = StripeDb::ServicePlan.joins(:plan_package).active.where(%(plan_packages.active = TRUE)).order('plan_packages.position ASC')
        render 'service_admin_panel/service_subscriptions/service_subscriptions/upgrade'
      end
    else
      @available_plans = StripeDb::ServicePlan.joins(:plan_package).active.where(%(plan_packages.active = TRUE)).order('plan_packages.position ASC')
      render 'service_admin_panel/service_subscriptions/service_subscriptions/upgrade'
    end
  end

  unless Rails.env.production?
    member_action :deactivate, method: :post do
      resource.deactivate!
      redirect_to resource_path
    end
    member_action :activate, method: :post do
      resource.activate!
      redirect_to resource_path
    end
    action_item :deactivate, only: :show do
      link_to('Deactivate', [:deactivate, :service_admin_panel, resource], method: :post) if resource.service_status != 'deactivated'
    end
    action_item :activate, only: :show do
      link_to('Activate', [:activate, :service_admin_panel, resource], method: :post) if resource.service_status != 'active'
    end
  end

  member_action :cancel, method: :post do
    if %w[active trialing].include?(resource.status) && resource.canceled_at.blank?
      if [true, 'true'].include?(params[:cancel_at_period_end])
        si = resource.stripe_item
        si.cancel_at_period_end = true
        si.save
        StripeDb::ServiceSubscription.create_or_update_from_stripe(resource.stripe_id)
        resource.reload
        end_of_period = DateTime.strptime(resource.cancel_at.to_s, '%s').in_time_zone(resource.user.timezone).strftime('%d %b %I:%M %p %Z')
        flash[:success] = "Subscription will be cancelled #{end_of_period}.\n CANCELED_AT and STATUS will be updated soon after receiving webhook, DON'T CANCEL AGAIN!!!"
      elsif [false, 'false'].include?(params[:cancel_at_period_end])
        resource.stripe_item.delete
        flash[:success] = "Subscription will be canceled immediately.\n CANCELED_AT and STATUS will be updated soon after receiving webhook, DON'T CANCEL AGAIN!!!"
      end
    end
    redirect_to resource_path(resource.id)
  end

  action_item :upgrade, only: :show do
    link_to('Upgrade', [:upgrade, :service_admin_panel, resource]) if resource.service_status == 'active'
  end

  filter :customer, label: 'Stripe Customer ID'
  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :stripe_plan_id, label: 'Plan ID'
  filter :stripe_plan_plan_package_id_eq, label: 'Package', as: :select, collection: proc { PlanPackage.all.order(position: :asc).map { |p| [p.name, p.id] } }
  filter :status, as: :select, collection: proc { StripeDb::ServiceSubscription::STRIPE_STATUSES }
  filter :service_status, as: :select, collection: proc { StripeDb::ServiceSubscription::SERVICE_STATUSES }
  filter :created_at
  filter :start_date
  filter :current_period_start
  filter :current_period_end
  filter :cancel_at
  filter :canceled_at
  filter :trial_start
  filter :trial_end
  filter :trial_suspended_at
  filter :suspended_at
  filter :grace_at
  filter :affiliate_everflow_transaction_transaction_id_eq, label: 'Everflow Transaction ID'

  index do
    selectable_column

    column :id
    column 'Plan' do |obj|
      link_to obj.stripe_plan.plan_package&.name, service_admin_panel_stripe_db_service_plan_path(obj.stripe_plan_id)
    end
    column :user
    column :service_status
    column :affiliate_everflow_transaction do |obj|
      if obj.affiliate_everflow_transaction
        link_to obj.affiliate_everflow_transaction.transaction_id, service_admin_panel_affiliate_everflow_transaction_path(obj.affiliate_everflow_transaction)
      end
    end
    column :start_date
    column :trial_start
    column :trial_end
    column :current_period_end
    column :grace_at
    column :suspended_at
    column :trial_suspended_at
    column :cancel_at
    column 'Upgrade' do |object|
      link_to('Upgrade', [:upgrade, :service_admin_panel, object]) if object.service_status == 'active'
    end
    actions
  end

  show do
    columns do
      column do
        panel 'Stripe Subscriptions Details' do
          attributes_table_for resource do
            row :stripe_id
            row :user
            row :organization
            row :plan do |obj|
              link_to([obj.stripe_plan.plan_package.name, obj.stripe_plan.formatted_interval, obj.stripe_plan.formatted_price].join(' '), [:service_admin_panel, obj.stripe_plan]) if obj.stripe_plan&.plan_package
            end
            row :customer
            row :status
            row :service_status
            row :affiliate_everflow_transaction do |obj|
              if obj.affiliate_everflow_transaction
                link_to obj.affiliate_everflow_transaction.transaction_id, service_admin_panel_affiliate_everflow_transaction_path(obj.affiliate_everflow_transaction)
              end
            end
            row :start_date
            row :trial_start
            row :trial_end
            row :cancel_at
            row :canceled_at
            row :current_period_start
            row :current_period_end
            row :grace_at
            row :suspended_at
            row :trial_suspended_at
            row :created_at
            row :updated_at
          end
          if resource.canceled_at.blank?
            render partial: 'service_admin_panel/service_subscriptions/cancel'
          end
        end
      end
      column do
        panel 'Logs' do
          table_for resource.log_data.versions do
            column :status do |obj|
              obj.data['c']['service_status']
            end
            column :plan do |obj|
              if obj.data['c']['stripe_plan_id']
                plan = StripeDb::ServicePlan.find(obj.data['c']['stripe_plan_id'])
                link_to plan.nickname, service_admin_panel_stripe_db_service_plan_path(plan)
              end
            end
            column :date do |obj|
              DateTime.strptime((obj.data['ts'] / 1000).to_s, '%s')
            end
          end
        end
        panel 'Plan Info' do
          attributes_table_for resource.stripe_plan do
            row :id
            row 'Name' do |obj|
              link_to obj.nickname, service_admin_panel_stripe_db_service_plan_path(obj)
            end
            row :active
            row :amount, &:formatted_price
            row :interval, &:formatted_interval
            row :trial_period_days
            row 'Stripe ID', &:stripe_id
            row :created_at
          end
        end
      end
    end
    if resource.user
      panel 'Transactions' do
        table_for resource.payment_transactions.order(checked_at: :desc) do
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
      f.input :status, as: :select, collection: StripeDb::ServiceSubscription::STRIPE_STATUSES
      f.input :service_status, as: :select, collection: StripeDb::ServiceSubscription::SERVICE_STATUSES
      f.input :user, as: :select, collection: User.all.order(display_name: :asc).pluck(:display_name, :id)
      f.input :organization
      f.input :grace_at
      f.input :suspended_at
      f.input :trial_suspended_at
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
  end
end
