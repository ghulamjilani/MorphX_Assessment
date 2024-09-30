# frozen_string_literal: true

class DropboxController < ApplicationController
  before_action :authenticate_dropbox, only: %i[index show]

  def authorize
    if params[:oauth_token]
      save_dropbox_access_token
      flash[:success] = I18n.t('controllers.dropbox.linked_succesfully')
    else
      flash[:error] = I18n.t('controllers.dropbox.link_failed')
      logger.info "Dropbox auth was declined. Params: #{params.inspect}"
    end
    redirect_to session.delete(:return_to_url) || root_url
  end

  def disconnect
    current_user.update_attribute :dropbox_token, nil
    flash[:success] = I18n.t('controllers.dropbox.unlinked_succesfully')
    redirect_back fallback_location: root_path
  end

  def index
    respond_to do |format|
      format.json { render json: current_user.dropbox_assets(params[:root_dir]) }
    end
  end

  def show
    redirect_to current_user.dropbox_repo.get_media(params[:id])
  end

  private

  def authenticate_dropbox
    unless dropbox_authenticated?
      respond_to do |format|
        format.json { render json: {}, status: 401 }
        format.any  { head 401 }
      end
    end
  end
end
