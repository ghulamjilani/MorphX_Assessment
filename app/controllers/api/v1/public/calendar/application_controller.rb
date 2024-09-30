# frozen_string_literal: true

class Api::V1::Public::Calendar::ApplicationController < Api::V1::Public::ApplicationController
  def envelope(json, status = 'OK', message = nil)
    json.status status
    json.message message if message

    if block_given?
      json.response do
        yield
      end
    end

    json.pagination do
      json.limit @limit
      json.offset @offset
      json.count @count

      if @offset && @limit && @count
        @current_page = (@offset + @limit) / @limit
        json.current_page @current_page
        json.total_pages (@count + @limit - 1) / @limit
      end
    end
  end
end
