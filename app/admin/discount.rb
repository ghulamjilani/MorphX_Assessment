# frozen_string_literal: true

ActiveAdmin.register Discount do
  menu parent: 'Ledger'

  actions :all
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :name, hint: I18n.t('activeadmin.discounts.hints.name').html_safe
      f.input :target_ids, label: 'Target Ids', as: :text, input_html: { value: f.object.target_ids.join(',') },
                           hint: I18n.t('activeadmin.discounts.hints.target_ids').html_safe
      f.input :target_type, as: :select, collection: %w[Livestream Immersive Replay Session Channel],
                            hint: I18n.t('activeadmin.discounts.hints.target_type').html_safe
      f.input :usage_count_per_user, hint: I18n.t('activeadmin.discounts.hints.usage_count_per_user').html_safe
      f.input :usage_count_total, hint: I18n.t('activeadmin.discounts.hints.usage_count_total').html_safe
      f.input :expires_at, as: :datetime_picker, hint: I18n.t('activeadmin.discounts.hints.expires_at').html_safe
      f.input :min_amount_cents, hint: I18n.t('activeadmin.discounts.hints.min_amount_cents').html_safe
      f.input :amount_off_cents, hint: I18n.t('activeadmin.discounts.hints.amount_off_cents').html_safe
      f.input :percent_off_precise, hint: I18n.t('activeadmin.discounts.hints.percent_off_precise').html_safe
      f.input :is_valid, hint: I18n.t('activeadmin.discounts.hints.is_valid').html_safe
    end
    f.actions
  end
  controller do
    def permitted_params
      params.permit!
      params.tap do |attrs|
        if attrs[:discount] && attrs[:discount][:target_ids]
          attrs[:discount][:target_ids] = attrs[:discount][:target_ids].gsub(/[\r\n\s]/, '').split(/,\s*/)
        end
      end
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
