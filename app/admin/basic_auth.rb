# frozen_string_literal: true

ActiveAdmin.register_page 'Basic Auth' do
  menu parent: 'System'

  page_action :generate, method: :post do
    login = params[:login]
    password = params[:password]
    basic_auth_token = ActionController::HttpAuthentication::Basic.encode_credentials(ENV['PORTAL_API_LOGIN'],
                                                                                      ENV['PORTAL_API_PASSWORD'])
    redirect_to service_admin_panel_basic_auth_path, notice: basic_auth_token
  end

  content do
    columns do
      column do
        panel 'Create Basic Auth token' do
          form decorate: true, action: service_admin_panel_basic_auth_generate_path, method: :post do |f|
            table do
              columns do
                column do
                  f.label 'Login', for: :username, class: 'label'
                  para do
                    f.input id: :username, name: :login, size: 40
                  end
                  f.label 'Password', for: :password, class: 'label'
                  para do
                    f.input id: :password, name: :password, size: 40
                  end
                  para do
                    f.input :submit, type: :submit
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
