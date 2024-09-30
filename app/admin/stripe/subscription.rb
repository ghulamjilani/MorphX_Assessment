# frozen_string_literal: true

ActiveAdmin.register Subscription, as: 'Channel Subscription Package' do
  menu parent: 'Stripe'

  actions :all

  filter :user_id, label: 'User ID'
  filter :channel, as: :select, collection: proc {
                                              Channel.joins(:subscription).order(title: :asc).distinct.pluck(:title, :id)
                                            }
  filter :enabled, as: :radio

  show do
    columns do
      column do
        panel 'Channel Subscription Info' do
          attributes_table_for resource do
            row :id
            row :channel
            row :user
            row :description
            row :enabled
            row :created_at
            row :updated_at
          end
        end
      end
      column do
        panel 'Plans' do
          table_for resource.plans do
            column :id do |obj|
              link_to "#{obj.id} (view)", service_admin_panel_channel_plan_path(obj)
            end
            column 'Name', &:nickname
            column 'Replays', &:im_replays
            column :active
            column :amount
            column :interval
            column :interval_count
            column :trial_period_days
            column 'Stripe ID', &:stripe_id
            column :created_at
          end
        end
      end
    end
    columns do
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
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
