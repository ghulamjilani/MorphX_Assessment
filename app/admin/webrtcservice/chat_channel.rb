# frozen_string_literal: true

ActiveAdmin.register_page 'Webrtcservice::ChatChannel' do
  menu parent: 'Webrtcservice', label: 'Chat Channels'

  content title: 'Webrtcservice' do
    panel 'Chat Channels' do
      channels = ChatChannel.all
      if channels
        table_for channels do
          column('ID') { |item| item['id'] }
          column('Session ID') { |item| item['session_id'] }
          column('Webrtcservice ID') { |item| item['webrtcservice_id'] }
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
