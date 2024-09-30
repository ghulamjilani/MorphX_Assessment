# frozen_string_literal: true

module LanguagesHelper
  def language_list
    # Adds all the languages in the languages.json file
    @language_list ||= JSON.parse(language_file)
  end

  def format_lang(code)
    language_list.key(code)
  rescue StandardError
    'English'
  end

  def language_file
    # Read language json file
    language_file_path = File.expand_path("#{Rails.root}/app/custom_libs/languages/languages.json", __FILE__)
    @language_file ||= File.read(language_file_path)
  end
end
