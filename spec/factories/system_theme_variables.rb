# frozen_string_literal: true
FactoryBot.define do
  factory :system_theme_variable do
    association :system_theme
    name { Forgery('lorem_ipsum').words(2) }
    group_name { SystemThemeVariable::GROUP_NAMES.sample }
    property { SystemThemeVariable::PROPERTIES.keys.sample }
    value { Forgery('basic').hex_color }
    state { SystemThemeVariable::STATES.sample }
  end
  factory :aa_stub_system_theme_variables, parent: :system_theme_variable
end
