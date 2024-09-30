# frozen_string_literal: true

ActiveAdmin.register_page 'Webrtcservice::ChatMember' do
  menu parent: 'Webrtcservice', label: 'Chat Members'

  content title: 'Webrtcservice' do
    panel 'Chat Members' do
      members = ChatMember.order(created_at: :desc).all
      if members
        table_for members do
          column('ID') { |item| item['id'] }
          column('Name') { |item| item['name'] }
          column('Location') { |item| item['location'] }
          column('IP Address') { |item| item['ip_address'] }
          column('UserAgent') { |item| item['user_agent'] }
          column('Created at') { |item| item['created_at'] }
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
