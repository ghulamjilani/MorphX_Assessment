# frozen_string_literal: true

class SharesController < ApplicationController
  before_action :authenticate_user!

  skip_before_action :authenticate_user!, only: [:increment]
  before_action :sanitize_provider, only: [:increment]
  before_action :sanitize_model,    only: [:increment]
  before_action :set_current_organization

  def email
    emails = params[:emails].to_s.split(',').map(&:strip).grep(Devise.email_regexp).uniq

    render json: { emails:   'At least one email should be set' }, status: 422 and return unless emails.count.positive?
    render json: { subject:  'Subject can\'t be blank' }, status: 422 and return if params[:subject].blank?
    render json: { body:     'Body can\'t be blank' }, status: 422 and return if params[:body].blank?
    render json: { emails:   'Something went wrong' }, status: 422 and return unless %w[User Channel Session Video
                                                                                        Recording Blog::Post].include?(params[:klass])

    klass = params[:klass].constantize
    model = klass.find(params[:model_id])

    unless AbilityLib::Legacy::Ability.new(current_user).can?(
      :email_share, model
    )
      render json: { emails: 'Something went wrong' },
             status: 422 and return
    end

    emails.each do |email|
      ::Mailer.share_via_email(email, params[:body], params[:subject]).deliver_later

      model.shares_count = model.shares_count + 1
      model.save(validate: false) # because otherwise you need to set whether it is free or not but increment is simple
    end

    if emails.present? && user_signed_in? && model.is_a?(Session)
      TodoAchievement.find_or_create_by(user: current_user, type: TodoAchievement::Types::SHARE_A_SESSION)
    end

    head :ok
  end

  def increment
    model = params[:model].capitalize.constantize.find(params[:id])

    model = model.session if model.is_a?(Video)
    model.shares_count = model.shares_count + 1
    model.save(validate: false) # because otherwise you need to set whether it is free or not but increment is simple

    if user_signed_in? && model.is_a?(Session)
      TodoAchievement.find_or_create_by(user: current_user, type: TodoAchievement::Types::SHARE_A_SESSION)
    end
    head :ok
  end

  def refer_friends
    errors = []
    emails = params[:emails].to_s.split(',').collect(&:strip).compact

    emails.each do |email|
      if User.exists?(email: email)
        errors << "User with #{email} email has already been invited"
      end
    end

    if emails.size.zero?
      errors << 'At least one email has to be present'
    end

    last_error_index = 0
    errors.each_with_index do |error_message, index|
      last_error_index = index + 1
      flash.now["error#{last_error_index}".to_sym] = error_message
    end

    succesfully_invited_users = []
    failed_to_invite_users    = []

    if errors.blank?
      emails.each do |email|
        user = User.invite!({ email: email }, current_user, &:before_create_generic_callbacks_and_skip_validation)

        if user.valid?
          succesfully_invited_users << user
        else
          failed_to_invite_users << user
        end
      end
    end

    last_success_index = 0
    succesfully_invited_users.each_with_index do |user, index|
      last_success_index = index + 1
      flash.now["success#{last_success_index}".to_sym] = "#{user.email} has been succesfully invited"
    end

    failed_to_invite_users.each_with_index do |user, index|
      last_error_index = index + 1
      flash.now["success#{last_error_index}".to_sym] = "#{user.email} does not seem like a valid email"
    end

    respond_to(&:js)
  end

  private

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
  end

  def sanitize_provider
    providers = %i[
      facebook
      twitter
      linkedin
      pinterest
      tumblr
      reddit
      gplus
    ]

    unless providers.include?(params[:provider].to_sym)
      raise "can not interpret - #{params[:provider].to_sym}"
    end
  end

  def sanitize_model
    models = %i[
      session
      channel
      user
      organization
      video
      recording
    ]

    unless models.include?(params[:model].to_sym)
      raise "can not interpret - #{params[:model].to_sym}"
    end
  end
end
