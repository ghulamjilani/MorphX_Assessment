# frozen_string_literal: true

ActiveAdmin.register_page 'Webrtcservice::ChatBan' do
  menu parent: 'Webrtcservice', label: 'Chat Bans'

  content title: 'Webrtcservice' do
    panel 'Chat Bans' do
      bans = ChatBan.order(created_at: :desc).all
      if bans
        table_for bans do
          column('ID') { |item| item['id'] }
          column('User ID') { |item| item['user_id'] }
          column('Channel ID') { |item| item['channel_id'] }
          column('Banned ID') { |item| item['banned_id'] }
          column('Banned Type') { |item| item['banned_type'] }
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
