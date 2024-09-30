# frozen_string_literal: true

ActiveAdmin.register ::Partner, as: 'Partners' do
  menu parent: 'Sales'

  actions :all, except: :destroy

  filter :type
  filter :title
  filter :rid
  filter :hosts
  filter :category_id, as: :select, collection: proc { ChannelCategory.pluck(:name, :id) }
  filter :immerss_term_percent
  filter :influencer_term_percent
  filter :cookie_length
  filter :country_code

  index do
    selectable_column
    column :id
    column :type
    column :title
    column :rid
    column :hosts
    column :category_id
    column :immerss_term_percent
    column :influencer_term_percent
    column :cookie_length
    actions
  end

  form do |f|
    f.inputs do
      f.input :type, as: :select, collection: ['none'].to_a
      f.input :title
      f.input :rid
      f.input :hosts, as: :text, input_html: { value: f.object.hosts.join(',') }
      f.input :category_id, as: :select, collection: ChannelCategory.pluck(:name, :id)
      f.input :immerss_term_percent
      f.input :influencer_term_percent
      f.input :cookie_length
      f.input :country_code
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit!
      if params[:action] == 'create' || params[:action] == 'update'
        params.tap do |attrs|
          attrs[:partner][:hosts] = attrs[:partner][:hosts].gsub(/[\r\n\s]/, '').split(/,\s*/)
        end
      end
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
