# frozen_string_literal: true

require 'rubygems'
require 'pry'

File.open('logfile') do |f|
  f.each_line do |l|
    # puts l.scan(/HTTP_USER_AGENT"=>"([^"]*)"/)
    puts l.scan(/HTTP_X_FORWARDED_FOR"=>"([^"]*)"/)
  end
end
