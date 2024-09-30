# frozen_string_literal: true
class SystemThemeVariable < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  GROUP_NAMES = %w[background buttons toggless typographics shadows borders].freeze
  STATES = %w[main hover focus disabled active].freeze

  belongs_to :system_theme
  validates :group_name, inclusion: { in: SystemThemeVariable::GROUP_NAMES }
  validates :state, inclusion: { in: SystemThemeVariable::STATES }

  PROPERTIES = {
    # BACKGROUND
    'bg__main': 'page background',
    'bg__secondary': 'second page background, light blue on unite',
    'bg__content': 'content section, navbars',
    'bg__content__secondary': 'sections inside bg__content',
    'bg__header': 'header bg',
    'bg__label': 'dark blue on unite',
    'bg__dropdowns': 'dropdowns, selects',
    'bg__tooltip': 'tooltips bg',
    # BUTTONS
    'btn__main': 'default btn style [red on unite]',
    'btn__secondary': 'second default btn style [solid grey on unite]',
    'btn__bordered': 'borderred btn borderred [white on unite]',
    'btn__save': 'save btns or etc for modals, [red on unite (btn__main)]',
    'btn__cancel': 'cancel btn or etc borderred [white on unite(btn__bordered)]',
    'btn__subscribe': 'subscribe btn [red on unite(btn__main)]',
    # TYPOGRAPHICS
    # Headers
    'tp__h1': 'home page header',
    'tp__h2': 'page title',
    'tp__h3': 'session name, company name',
    # Main
    'tp__main': 'all texts',
    'tp__secondary': 'lighter then mail',
    'tp__links': '  tp__inputs',
    'tp__inputs': 'validation red (error text, input border on error)',
    'tp__active': 'active Nav, active tabs etc(best if used same colors for radioBtns active and checkbox active)',
    'tp__icons': 'same that tp__main',
    # SHADOWS
    'sh__main': 'content section',
    'sh__secondary': ' dropdown',
    'sh__modals': 'modals',
    # BORDERS
    'border__modals': 'sugest remove',
    'border__table': '2 colors (first for borders and second for table header 20% lighter or the same)',
    'border__dividers': 'none',
    'border__content': 'sections'
  }.freeze
end
