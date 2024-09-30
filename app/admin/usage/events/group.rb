# frozen_string_literal: true

ActiveAdmin.register_page 'Usage::Event::Group' do
  menu parent: 'Usage', label: 'Events Group'

  sidebar :filters do
    usage_event_group_params = params.fetch(:usage_event_group, {})

    active_admin_form_for ::Usage::Event::Group.new,
                          url: service_admin_panel_usage_event_group_path,
                          method: :get,
                          html: { class: 'filter_form' } do |f|
      f.inputs do
        f.input :id, label: 'Id', input_html: { value: usage_event_group_params[:id] }
        f.input :model_id, label: 'Model Id', input_html: { value: usage_event_group_params[:model_id] }
        f.input :model_type, input_html: { value: usage_event_group_params[:model_type] }
        f.input :event_type, input_html: { value: usage_event_group_params[:event_type] }
        f.input :start_time, as: :datetime_picker, label: 'Start Date',
                             input_html: { name: :start_time, value: params[:start_time] }
        f.input :end_time, as: :datetime_picker,
                           label: 'End Date',
                           input_html: { name: :end_time, value: params[:end_time] }
      end
      f.submit 'Apply'
      para do
        link_to 'Reset Filters', service_admin_panel_usage_event_group_path, class: 'button'
      end
    end
  end

  page_action :update, method: :put do
    # TODO
  end

  content do
    query = ::Usage::Event::Group
    usage_event_group_params = params.fetch(:usage_event_group, {})
    if usage_event_group_params[:start_time] || usage_event_group_params[:end_time]
      start_time = DateTime.parse((usage_event_group_params[:start_time] || 1.year.ago).to_s)
      end_time = DateTime.parse((usage_event_group_params[:end_time] || Time.now.utc).to_s)
      query = query.where(start_at: (start_time..end_time))
    end

    query = query.where(id: usage_event_group_params[:id]) if usage_event_group_params[:id].present?
    query = query.where(model_type: usage_event_group_params[:model_type]) if usage_event_group_params[:model_type].present?
    query = query.where(model_id: usage_event_group_params[:model_id]) if usage_event_group_params[:model_id].present?
    query = query.where(event_type: usage_event_group_params[:event_type]) if usage_event_group_params[:event_type].present?

    if params[:order]
      order_params = params[:order].split('_')
      order_direction = order_params.pop
      query = query.order("#{order_params.join('_')} #{order_direction}")
    else
      query = query.order(created_at: :desc)
    end

    page = (params[:page] || 1).to_i
    limit = (params[:per_page] || 15).to_i
    collection = query.page(page).per(limit)

    def collection.length
      to_a.size
    end

    paginated_collection(collection, download_links: false, sortable: true, pagination_total: true) do
      table_for collection, class: 'index_table index', sortable: true do
        column('id', &:id)
        column('channel_id', &:channel_id)
        column('organization_id', &:organization_id)
        column('model_type', &:model_type)
        column('model_id', &:model_id)
        column('event_type', &:event_type)
        column('start_at', &:start_at)
        column('end_at', &:end_at)
        column('value', &:value)
      end
    end
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
