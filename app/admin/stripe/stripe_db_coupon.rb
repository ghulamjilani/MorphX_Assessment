# frozen_string_literal: true

ActiveAdmin.register StripeDb::Coupon, as: 'Coupons' do
  menu parent: 'Stripe'

  actions :all, except: %i[edit update]

  index do
    selectable_column
    id_column
    column 'Code', &:stripe_id
    column :name
    column :amount_off
    column :percent_off_precise
    column :duration
    column :duration_in_months
    column :redeem_by
    column :target_type do |obj|
      obj.target_type.presence || 'All'
    end
    column :target_id do |obj|
      obj.target_id.presence || 'All'
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row 'Code', &:stripe_id
      row :name
      row :amount_off
      row :percent_off_precise
      row :duration
      row :duration_in_months
      row :target_type do |obj|
        obj.target_type.presence || 'All'
      end
      row :target_id do |obj|
        obj.target_id.presence || 'All'
      end
      row :redeem_by
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :stripe_id, label: 'CODE', placeholder: '20OFF', hint: I18n.t('activeadmin.stripe_db.coupons.hints.stripe_id')
      f.input :name, placeholder: 'First purchase discount', hint: I18n.t('activeadmin.stripe_db.coupons.hints.name'), input_html: { maxlength: 40 }
      f.input :target_id, label: 'Target Id', hint: I18n.t('activeadmin.stripe_db.coupons.hints.target_id')
      f.input :target_type, as: :select, collection: [['Business Subscription Plan', 'StripeDb::ServicePlan']], hint: I18n.t('activeadmin.stripe_db.coupons.hints.target_type')
      f.input :amount_off, hint: I18n.t('activeadmin.stripe_db.coupons.hints.amount_off')
      f.input :percent_off_precise, label: 'Percent Off', hint: I18n.t('activeadmin.stripe_db.coupons.hints.percent_off_precise')
      f.input :duration, as: :select, collection: StripeDb::Coupon::DURATIONS, hint: I18n.t('activeadmin.stripe_db.coupons.hints.duration')
      f.input :duration_in_months, hint: I18n.t('activeadmin.stripe_db.coupons.hints.duration_in_months')
      f.input :redeem_by, hint: I18n.t('activeadmin.stripe_db.coupons.hints.redeem_by'), as: :datetime_picker
      f.input :is_valid, as: :hidden, input_html: { value: 1 }
      f.input :push_to_stripe, as: :hidden, input_html: { value: 1 }
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
