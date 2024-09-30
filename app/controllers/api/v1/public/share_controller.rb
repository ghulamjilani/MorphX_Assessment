# frozen_string_literal: true

class Api::V1::Public::ShareController < Api::V1::ApplicationController
  skip_before_action :authorization, if: -> { !auth_header_present? && action_name == 'index' }

  def index
    if supported_classes.include?(params[:model_type].to_s.singularize.classify)
      @share_model = params[:model_type].singularize.classify.constantize.find(params[:model_id])
      return render_json(401, 'You cannot share this item') unless AbilityLib::Legacy::Ability.new(current_user).can?(
        :share, @share_model
      )
    else
      render_json(401, 'You cannot share this item')
    end
  end

  def email
    emails = params[:emails].to_s.split(',').map(&:strip).grep(Devise.email_regexp).uniq

    render_json(422, 'At least one email should be set') and return unless emails.count.positive?
    render_json(422, 'Something went wrong') and return unless supported_classes.include?(params[:model_type])

    klass = params[:model_type].constantize
    model = klass.find(params[:model_id])

    render_json(422, 'Something went wrong') and return unless AbilityLib::Legacy::Ability.new(current_user).can?(
      :email_share, model
    )

    emails.each do |email|
      ::Mailer.share_model_via_email(email, model).deliver_later
      model.shares_count = model.shares_count + 1
      model.save(validate: false) # because otherwise you need to set whether it is free or not but increment is simple
    end

    if emails.present? && user_signed_in? && model.is_a?(Session)
      TodoAchievement.find_or_create_by(user: current_user,
                                        type: TodoAchievement::Types::SHARE_A_SESSION)
    end

    head :ok
  end

  private

  def supported_classes
    %w[User Channel Session Video Recording Blog::Post]
  end

  def auth_header_present?
    request.headers['Authorization'].present?
  end
end
