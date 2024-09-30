# frozen_string_literal: true

class RemoteValidationsController < ApplicationController
  respond_to :json, only: %i[user_email channel_title organization_name social_link]

  def user_email
    email = nil
    if params[:user]
      email = params[:user][:email].to_s.downcase
    elsif params[:profile]
      email = params[:profile][:email].to_s.downcase
    end

    result = if user_signed_in?
               User.where.not(id: current_user.id).exists?(email: email)
             else
               User.exists?(email: email)
             end

    respond_with !result
  end

  def user_slug
    @slug = params[:slug].to_s.downcase.strip

    @valid = false

    if @slug.blank?
      flash.now[:error] = "Custom URLs can't be blank"
    elsif !(@slug =~ /[^A-Za-z\-0-9]/).nil?
      flash.now[:error] =
        "Custom URLs can't contain letters from different alphabets, special and upper case characters."
    elsif current_user.slug != @slug.parameterize && User.where(slug: @slug).present?
      flash.now[:error] = 'This custom URL has already been taken'
    else
      @valid = true
    end

    respond_to do |format|
      format.js { render "remote_validations/#{__method__}" }
    end
  end

  # Check if channel already exists with given title (use it for remote jquery validation)
  def channel_title
    respond_with true and return if params[:channel][:title].blank?

    id = params[:id].blank? ? -1 : params[:id].to_i
    name = params[:channel][:title].downcase
    exists = Channel.not_archived.exists?(['lower(channels.title) = ? AND channels.id != ?', name, id])
    respond_with !exists
  end

  # Check if company already exists with given name (use it for remote jquery validation)
  def organization_name
    respond_with true and return if params[:organization][:name].blank?

    id = params[:id].blank? ? -1 : params[:id].to_i
    name = params[:organization][:name].downcase
    exists = Organization.exists?(['lower(organizations.name) = ? AND organizations.id != ?', name, id])
    respond_with !exists
  end

  def social_link
    respond_with SocialLink.new(link: params[:link], provider: params[:provider]).validate()
  end
end
