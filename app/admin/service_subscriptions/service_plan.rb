# frozen_string_literal: true

ActiveAdmin.register StripeDb::ServicePlan do
  menu parent: I18n.t('activeadmin.stripe_db.menu')
  actions :all, except: %i[new destroy]

  member_action :update_from_stripe, method: :post do
    resource.update_from_stripe
    redirect_to resource_path(resource.id)
  end
  action_item :update_from_stripe, only: :show do
    link_to 'Update From Stripe', update_from_stripe_service_admin_panel_stripe_db_service_plan_path(resource),
            data: { method: :post, confirm: 'Are you sure?' }
  end
  show do
    columns do
      column do
        panel 'Plan Info' do
          attributes_table_for resource do
            row :id
            row :plan_package
            row :active
            row 'Price', &:formatted_price
            row :trial_period_days
            row :interval
            row 'Stripe ID', &:stripe_id
            row :created_at
            row :updated_at
          end
        end
      end
      column do
        panel 'Statistics' do
          attributes_table_for resource do
            row 'Total' do
              resource.service_subscriptions.count
            end
            row 'Active' do
              resource.service_subscriptions.where(service_status: 'active').count
            end
            row 'Trial' do
              resource.service_subscriptions.where(service_status: 'trial').count
            end
            row 'Pending Deactivation' do
              resource.service_subscriptions.where(service_status: 'pending_deactivation').count
            end
            row 'Grace' do
              resource.service_subscriptions.where(service_status: 'grace').count
            end
            row 'Trial Suspended' do
              resource.service_subscriptions.where(service_status: 'trial_suspended').count
            end
            row 'Suspended' do
              resource.service_subscriptions.where(service_status: 'suspended').count
            end
            row 'Deactivated' do
              resource.service_subscriptions.where(service_status: 'deactivated').count
            end
          end
        end
      end
    end
  end
  form do |f|
    f.inputs do
      f.semantic_errors(*f.object.errors.attribute_names)
      f.input :active
      f.input :amount,
              hint: 'In cents. Warning: If you want to change price you should do it on stripe dashboard because API doesn\'t support this', required: true
      f.input :currency, input_html: { value: 'USD', placeholder: 'USD' }, required: true
      f.input :interval, as: :select, collection: %w[day month year], include_blank: false, required: true,
                         hint: 'Warning: If you want to change interval you should do it on stripe dashboard because API doesn\'t support this'
      f.input :interval_count,
              hint: '1 year/1 month. Warning: If you want to change interval_count you should do it on stripe dashboard because API doesn\'t support this', required: true
      f.input :trial_period_days
      f.input :nickname, hint: 'Plan Name'
      f.input :stripe_id, hint: 'Only if already present on Stripe'
      f.input :push_to_stripe, as: :boolean, hint: 'Send plan data to Stripe'
      f.actions
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
