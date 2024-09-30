# frozen_string_literal: true

ActiveAdmin.register_page 'Usage::Event::GroupUser' do
  menu parent: 'Usage', label: 'Events GroupUser'

  sidebar :filters do
    groupuser_params = params.fetch(:usage_event_group_user, {})

    active_admin_form_for ::Usage::Event::GroupUser.new,
                          url: service_admin_panel_usage_event_groupuser_path,
                          method: :get,
                          html: { class: 'filter_form' } do |f|
      f.inputs do
        f.input :id, label: 'Id', input_html: { value: groupuser_params[:id] }
        f.input :user_id, label: 'User Id', input_html: { value: groupuser_params[:user_id] }
        f.input :visitor_id, label: 'Visitor Id', input_html: { value: groupuser_params[:visitor_id] }
        f.input :events_group_id, label: 'Group Id', input_html: { value: groupuser_params[:events_group_id] }
      end
      f.submit 'Apply'
      para do
        link_to 'Reset Filters', service_admin_panel_usage_event_groupuser_path, class: 'button'
      end
    end
  end

  page_action :update, method: :put do
    # TODO
  end

  content do
    groupuser_params = params.fetch(:usage_event_group_user, {})

    query = ::Usage::Event::GroupUser
    query = query.where(id: groupuser_params[:id]) if groupuser_params[:id]
    query = query.where(user_id: groupuser_params[:user_id]) if groupuser_params[:user_id]
    query = query.where(visitor_id: groupuser_params[:visitor_id]) if groupuser_params[:visitor_id]
    query = query.where(events_group_id: groupuser_params[:events_group_id]) if groupuser_params[:events_group_id]

    if params[:order]
      order_params = params[:order].split('_')
      order_direction = order_params.pop
      query = query.order("#{order_params.join('_')} #{order_direction}")
    else
      query = query.order(created_at: :desc)
    end

    page = (params[:page] || 1).to_i
    limit = (params[:per_page] || 15).to_i
    collection = query.page(page).per(limit).includes(:events_group)

    def collection.length
      to_a.size
    end

    paginated_collection(collection, sortable: true, pagination_total: true) do
      table_for collection, class: 'index_table index', sortable: true do
        column('id', &:id)
        column('events_group') do |model|
          link_to(model.events_group_id, [:service_admin_panel, :usage_event_group, { usage_event_group: { id: model.events_group_id } }])
        end
        column('model_type', &:model_type)
        column('model_id', &:model_id)
        column('event_type', &:event_type)
        column('client_type', &:client_type)
        column('embed_domain', &:embed_domain)
        column('ip', &:ip)
        column('last_resolution', &:last_resolution)
        column('user_agent', &:user_agent)
        column('user_id', &:user_id)
        column('value', &:value)
        column('visitor_id', &:visitor_id)
      end
    end
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
