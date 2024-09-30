# frozen_string_literal: true

ActiveAdmin.register PlanPackage do
  menu parent: I18n.t('activeadmin.stripe_db.menu')
  actions :all, except: (Rails.env.development? ? [] : %i[destroy])

  show do
    columns do
      column do
        panel 'Plans' do
          table_for resource.plans do
            column :id
            column :amount, &:formatted_price
            column :interval, &:formatted_interval
            column :trial_period_days
            column :stripe_id
            column '' do |p|
              link_to 'Edit', edit_service_admin_panel_stripe_db_service_plan_path(p)
            end
            column '' do |p|
              link_to 'Update from Stripe', update_from_stripe_service_admin_panel_stripe_db_service_plan_path(p),
                      data: { method: :post, confirm: 'Are you sure?' }
            end
          end
        end
        panel 'Statistics' do
          table_for resource do
            column 'Total' do
              resource.service_subscriptions.count
            end
            column 'Active' do
              resource.service_subscriptions.where(service_status: 'active').count
            end
            column 'Trial' do
              resource.service_subscriptions.where(service_status: 'trial').count
            end
            column 'Pending Deactivation' do
              resource.service_subscriptions.where(service_status: 'pending_deactivation').count
            end
            column 'Grace' do
              resource.service_subscriptions.where(service_status: 'grace').count
            end
            column 'Trial Suspended' do
              resource.service_subscriptions.where(service_status: 'trial_suspended').count
            end
            column 'Suspended' do
              resource.service_subscriptions.where(service_status: 'suspended').count
            end
            column 'Deactivated' do
              resource.service_subscriptions.where(service_status: 'deactivated').count
            end
          end
        end
        panel 'Features' do
          table_for resource.feature_parameters.joins(:plan_feature).includes(:plan_feature).order('plan_features.name': :asc) do
            column :name do |p|
              p.plan_feature.name
            end
            column :value
            column :code do |p|
              link_to p.plan_feature.code, service_admin_panel_plan_feature_path(p.plan_feature)
            end
            column :description do |p|
              p.plan_feature.description
            end
            column '' do |p|
              link_to 'Edit', edit_service_admin_panel_feature_parameter_path(p)
            end
          end
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :name
      f.input :description
      f.input :position, required: true
      f.input :recommended
      f.input :custom
      f.input :active
    end
    f.inputs do
      f.has_many :plans do |p|
        p.input :active
        p.input :amount, hint: 'In cents', required: true
        p.input :currency, input_html: { value: 'USD', placeholder: 'USD' }, required: true
        p.input :interval, as: :select, collection: %w[day month year], include_blank: false, required: true
        p.input :interval_count, hint: '1 year/1 month', required: true
        p.input :trial_period_days, required: true
        p.input :nickname, hint: 'Plan Name'
        p.input :stripe_id, hint: 'Only if already present on Stripe'
        p.input :push_to_stripe, as: :boolean, hint: 'Send plan data to Stripe'
      end
    end
    f.inputs do
      render 'service_admin_panel/service_subscriptions/plan_packages/feature_parameters', { f: f, plan_package: f.object }
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
