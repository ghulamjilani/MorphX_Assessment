# frozen_string_literal: true

class Api::V1::Public::MindBody::SitesController < Api::V1::ApplicationController
  skip_before_action :authorization # FIXME: add user authenticate on create, and check access to this endpoint
  before_action :set_organization

  # FIXME: split create and update actions
  def create
    client = MindBodyLib::Api::Client.new(credentials: params)

    raise ActiveRecord::RecordInvalid unless (@a_link = client.activation_link)

    if (@site = @organization.mind_body_db_site)
      @site.update(remote_id: params[:site_id])
    else
      @site = MindBodyDb::Site.create!(remote_id: params[:site_id], organization: @organization)
    end

    render :create
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end
end
