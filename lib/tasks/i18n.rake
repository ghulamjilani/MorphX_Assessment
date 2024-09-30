# frozen_string_literal: true

unless Rails.env.test?
  task 'requirejs:precompile:external': :'i18n:js:export'
  task 'assets:precompile': :'i18n:js:export'
end
