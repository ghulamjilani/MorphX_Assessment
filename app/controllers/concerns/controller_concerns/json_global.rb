# frozen_string_literal: true

module ControllerConcerns::JsonGlobal
  extend ActiveSupport::Concern
  included do
    helper_method :envelope
  end

  def envelope(json, status = 'OK', message = nil)
    json.status status
    json.message message if message
    if block_given?
      json.response do
        yield
      end
    end

    @current_page = begin
      (@offset + @limit) / @limit
    rescue StandardError
      nil
    end

    json.limit          @limit        if @limit
    json.offset         @offset       if @offset
    begin
      json.total_pages (@count + @limit - 1) / @limit
    rescue StandardError
      json.total_pages nil
    end
    begin
      json.current_page (@offset + @limit) / @limit
    rescue StandardError
      json.current_page nil
    end
  end

  def render_json(status, text = nil, error = nil)
    notify_airbrake(error || text) if status == 500
    puts error.message if status == 500
    puts error.backtrace if status == 500

    text ||= 'OK'             if status == 200
    text ||= 'Created'        if status == 201
    text ||= 'Not found'      if status == 404
    text ||= 'Access denied'  if status == 401
    text ||= error.message    if status == 500

    text = text.full_errors if text.respond_to?(:full_errors)

    resp = Jbuilder.encode do |json|
      envelope(json, status, text)
    end
    render json: resp, status: status
  end
end
