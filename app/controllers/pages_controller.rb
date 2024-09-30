# frozen_string_literal: true

class PagesController < HighVoltage::PagesController
  before_action :set_current_organization

  layout proc { |_c| 'application' }

  def robots
    render plain: File.read(Rails.root.join("config/robots.#{Rails.env}.txt")),
           layout: false,
           content_type: 'text/plain'
  end

  def sitemap
    path = Rails.root.join('public', 'sitemaps', 'sitemap.xml')
    if File.exist?(path)
      render xml: open(path).read
    else
      render plain: 'Sitemap not found.', status: 404
    end
  end

  private

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
  end
end
