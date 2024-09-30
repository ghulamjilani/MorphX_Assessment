# frozen_string_literal: true

task 'robotstxt:write' => :environment do
  def get_binding
    binding # So that everything can be used in templates generated for the servers
  end

  def from_template(file)
    require 'erb'
    template = File.read(File.join(File.dirname(__FILE__), '..', '..', file))
    result = ERB.new(template, trim_mode: '-').result(get_binding)
  end

  config_content = from_template("config/robots.#{Rails.env}.txt.template.erb")
  File.open(Rails.root.join("config/robots.#{Rails.env}.txt"), 'w') { |f| f.write config_content }
end
