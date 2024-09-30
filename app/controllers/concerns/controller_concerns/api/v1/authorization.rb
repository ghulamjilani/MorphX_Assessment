# frozen_string_literal: true

module ControllerConcerns::Api::V1::Authorization
  extend ActiveSupport::Concern

  AVAILABLE_TYPES = %w[organization user guest refresh].freeze
  included do
    AVAILABLE_TYPES.each do |type|
      helper_method :"current_#{type}"
    end
  end

  def authentication
    raise(ArgumentError, I18n.t('controllers.concerns.controller_concerns.api.v1.authorization.errors.blank_jwt')) if jwt_from_header.blank?

    jwt_decoder.decode!
    case jwt_decoder.model.class.name
    when 'Auth::UserToken'
      @current_user = jwt_decoder.model.user
    when 'Guest'
      @current_guest = jwt_decoder.model
    when 'Organization'
      @current_organization = jwt_decoder.model
    else
      raise ActiveRecord::RecordNotFound, "Unsupported payload type #{jwt_decoder.type}"
    end
  end

  def authorization
    authentication
  rescue ArgumentError, ActiveRecord::RecordNotFound => e
    render_json(401, e.message)
  rescue JWT::DecodeError, ::Auth::Jwt::Errors::Error => e
    @current_user = @current_organization = @current_room_member = nil
    raise(NotAuthorizedError, e.message)
  end

  AVAILABLE_TYPES.each do |type|
    define_method("current_#{type}") do
      instance_variable_get("@current_#{type}")
    end
  end

  def current_user_or_guest
    current_user || current_guest
  end

  def jwt_decoder
    @jwt_decoder ||= ::Auth::Jwt::Decoder.new(jwt_from_header)
  end

  private

  def jwt_from_header
    header = request.headers['Authorization']
    header&.split(' ')&.last
  end
end
