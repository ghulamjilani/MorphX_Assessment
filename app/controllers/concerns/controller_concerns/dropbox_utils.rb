# frozen_string_literal: true

module ControllerConcerns::DropboxUtils
  extend ActiveSupport::Concern

  included do
    helper_method :dropbox_authorize_url
    helper_method :dropbox_client
    helper_method :dropbox_authenticated?
  end

  def dropbox_authorize_url
    session[:return_to_url] = request.url
    begin
      dropbox_session = DropboxSession.new(ENV['DROPBOX_KEY'], ENV['DROPBOX_SECRET'])
      current_user.update_attribute :dropbox_token, dropbox_session.serialize
      dropbox_session.get_authorize_url(authorize_dropbox_index_url)
    rescue StandardError
      nil
    end
  end

  def dropbox_client
    current_user.dropbox_repo.client
  end

  def dropbox_authenticated?
    dropbox_client.present?
  rescue StandardError
    false
  end

  private

  def save_dropbox_access_token
    dropbox_session = DropboxSession.deserialize(current_user.dropbox_token)
    # get_access_token modifies state and adds @access_token instance variable
    dropbox_session.get_access_token
    current_user.update_attribute :dropbox_token, dropbox_session.serialize
  end
end
