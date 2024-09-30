# frozen_string_literal: true

ActiveAdmin.register TranscodeTask do
  menu parent: 'Videos'

  batch_action :update_status do |ids|
    job_ids = TranscodeTask.where(id: ids).pluck(:job_id)
    task_statuses = client.statuses(job_ids)
    task_statuses.keys do |job_id|
      next unless (transcode_task = TranscodeTask.find_by(job_id: job_id))

      status = task_statuses[job_id]
      next if status.blank?

      transcode_task.update(
        status: status['status'],
        percent: status['percent'],
        error: status['error'],
        error_description: status['error_description']
      )
    end

    redirect_to collection_path, alert: 'Statuses updated'
  end

  scope(:all)
  scope(:Video, &:for_videos)
  scope(:Recording, &:for_recordings)

  filter :id
  filter :job_id
  filter :transcodable_type
  filter :transcodable_id
  filter :status
  filter :error
  filter :can_buy_subscription
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :job_id
    column :transcodable
    column :transcodable_id
    column :transcodable_type
    column :status do |transcode_task|
      lambda do
        return status_tag(true, label: transcode_task.status) unless transcode_task.completed?
        return status_tag('red', label: transcode_task.status) if transcode_task.error.to_i.positive?

        status_tag('green', label: transcode_task.status)
      end.call
    end
    column :percent
    column :error do |transcode_task|
      transcode_task.error.to_i.zero? ? nil : status_tag('red', label: 'YES')
    end
    column :error_description
    column :created_at

    actions defaults: true do |transcode_task|
      "<br>#{link_to 'Sync', update_status_service_admin_panel_transcode_task_path(transcode_task), class: 'member_link'}".html_safe
    end
  end

  form do |f|
    f.inputs do
      f.input :transcodable_type
      f.input :transcodable_id
      f.input :job_id
      f.input :error
      f.input :error_description
      f.input :status
      f.input :percent
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

  member_action :update_status, method: :get do
    control = ::Control::TranscodeTask.new(resource)
    control.update_status
    resource.reload

    flash[:success] = "Transcode status updated: #{resource.status}"

    redirect_back fallback_location: service_admin_panel_transcode_tasks_path
  end

  action_item :update_status, only: %i[edit show] do
    link_to 'Sync', update_status_service_admin_panel_transcode_task_path(resource)
  end
end
