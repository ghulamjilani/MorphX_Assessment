# frozen_string_literal: true

class UpdateVideoTitleAndUrl < ApplicationJob
  def perform(*_args)
    Video.joins(:room).where(short_url: nil).find_each do |v|
      v.recreate_short_urls
    rescue StandardError
      nil
    end
    Video.joins(:room).where(title: nil).find_each do |v|
      v.set_default_title
    rescue StandardError
      nil
    end
  end
end
