# frozen_string_literal: true

begin
  require 'irb/completion'
  branch = begin
    `git rev-parse --abbrev-ref HEAD`.to_s[0..5]
  rescue StandardError
    nil
  end
  IRB.conf[:PROMPT] ||= {}
  IRB.conf[:PROMPT][:RAILS_APP] = {
    PROMPT_I: "UnitePortal(#{Rails.env.to_s[0..2]})(#{branch})> ",
    PROMPT_N: nil,
    PROMPT_S: nil,
    PROMPT_C: nil,
    RETURN: "=> %s\n"
  }

  # Use the custom  prompt
  IRB.conf[:PROMPT_MODE] = :RAILS_APP
rescue StandardError => e
end
