# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    attr_accessor :uid

    identified_by :current_user
    identified_by :current_guest

    self.identifiers += [:uid]

    def connect
      identify_visitor
      logger.add_tags 'ActionCable', current_user&.display_name || current_guest&.public_display_name
    end

    protected

    def identify_visitor
      reject_unauthorized_connection unless (auth_websocket_token = ::Auth::WebsocketToken.find(request.params[:auth]))

      case auth_websocket_token.abstract_user_type
      when 'User'
        self.current_user = @current_user = auth_websocket_token.abstract_user
      when 'Guest'
        self.current_guest = @current_guest = auth_websocket_token.abstract_user
      end
      set_uid
    end

    def set_uid
      self.uid = if @current_user.present?
                   @current_user.id
                 elsif @current_guest.present?
                   @current_guest.id
                 elsif @visitor_id.present?
                   "_#{@visitor_id[-8..]}"
                 else
                   "__#{SecureRandom.urlsafe_base64[-8..]}"
                 end
    end
  end
end
