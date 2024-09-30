# frozen_string_literal: true

ActiveAdmin.register_page 'Config' do
  menu parent: 'Admin settings'

  page_action :update, method: :put do
    flash[:notice] = 'Success'
    oc = OverCreds.new(params[:active_config][:env] || Rails.env, Rails.env.development?)
    oc.default_config.write(params[:active_config][:default]) if Rails.env.development?
    oc.overridden_config.write(params[:active_config][:overridden])

    if !Rails.env.development? && system("/bin/bash -c 'kill -SIGUSR1 `cat /home/deployer/Portal/current/tmp/pids/puma.pid`'")
      flash[:notice] += '. and restarted'
    end
    redirect_back fallback_location: service_admin_panel_config_path
  end

  content do
    resource = Active::Config.new(env: (params[:env] || Rails.env))
    envs = Dir.glob("#{Rails.root}/config/environments/*.rb").map { |filename| File.basename(filename, '.rb') }

    active_admin_form_for resource, url: service_admin_panel_config_update_path, method: :put do |f|
      f.inputs do
        f.input :env, as: :select, collection: envs, include_blank: false
      end
      columns do
        column do
          panel 'Default Config' do
            f.inputs do
              f.input :default, as: :ace_editor, input_html: { data: { 'options-mode': 'yaml' } }, label: false,
                                value: resource.default
            end
          end
        end
        column do
          panel 'Overridden Config' do
            f.inputs do
              f.input :overridden, as: :ace_editor, input_html: { data: { 'options-mode': 'yaml' } }, label: false
            end
          end
        end

        column do
          panel 'Current Config' do
            f.inputs do
              f.input :current, as: :ace_editor, input_html: { data: { 'options-mode': 'yaml' } }, label: false
            end
          end
        end
      end
      f.submit 'Update'
    end
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
