# frozen_string_literal: true

ActiveAdmin.register_page 'Log::UserEvent' do
  menu parent: 'Log', label: 'UserEvent'

  sidebar :filters do
    active_admin_form_for Log::UserEvent.new, url: service_admin_panel_log_userevent_path, method: :get,
                                              html: { class: 'filter_form' } do |f|
      f.inputs do
        f.input :event_time, as: :datetime_picker, label: 'Start Date',
                             input_html: { name: :start_time, value: params[:start_time] }
        f.input :event_time, as: :datetime_picker, label: 'End Date',
                             input_html: { name: :end_time, value: params[:end_time] }
      end
      f.submit 'Apply'
    end
  end

  page_action :update, method: :put do
    # TODO
  end

  content do
    lue = if params[:start_time] || params[:end_time]
            start_time = DateTime.parse((params[:start_time] || 1.year.ago).to_s)
            end_time = DateTime.parse((params[:end_time] || Time.now.utc).to_s)
            Log::UserEvent.where(event_time: (start_time..end_time)).order(event_time: :desc)
          else
            Log::UserEvent.order(event_time: :desc)
          end

    paginated_collection(lue.page(params[:page]).per(15), download_links: false, sortable: true) do
      table_for collection, class: 'index_table index' do
        column('id', &:id)
        column('platform', &:platform)
        column('service', &:service)
        column('event_type', &:event_type)
        column('user_id', &:user_id)
        column('user_agent', &:user_agent)
        column('user_ip', &:user_ip)
        column('page', &:page)
        column('data', &:data)
        column('event_time utc') { |item| item.event_time.utc }
      end
    end
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
