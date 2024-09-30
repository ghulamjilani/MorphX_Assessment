# frozen_string_literal: true
FactoryBot.define do
  factory :system_theme do
    name { Forgery('lorem_ipsum').word }
    after(:create) do |theme|
      white_styles = [
        # backgrounds
        { name: 'Main', property: 'bg__main', group_name: 'background', state: 'main', value: '#FAFAFA' },
        { name: 'Secondary', property: 'bg__secondary', group_name: 'background', state: 'main', value: '#E6EFF1' },
        { name: 'Content', property: 'bg__content', group_name: 'background', state: 'main', value: '#FFFFFF' },
        { name: 'Content Secondary', property: 'bg__content__secondary', group_name: 'background', state: 'main',
          value: '#095f730d' },
        { name: 'Header', property: 'bg__header', group_name: 'background', state: 'main', value: '#FAFAFA' },
        { name: 'Label', property: 'bg__label', group_name: 'background', state: 'main', value: '#095F73' },
        { name: 'Dropdowns', property: 'bg__dropdowns', group_name: 'background', state: 'main', value: '#FFFFFF' },
        { name: 'Tooltip', property: 'bg__tooltip', group_name: 'background', state: 'main', value: '#FFFFFF' },
        # buttons
        { name: 'Main', property: 'btn__main', group_name: 'buttons', state: 'main', value: '#F23535' },
        { name: 'Secondary', property: 'btn__secondary', group_name: 'buttons', state: 'main', value: '#E5E5E5' },
        { name: 'Tetriary', property: 'btn__tetriary', group_name: 'buttons', state: 'main', value: '#FFFFFF' },
        { name: 'Bordered', property: 'btn__bordered', group_name: 'buttons', state: 'main', value: '#095F73' },
        { name: 'Save', property: 'btn__save', group_name: 'buttons', state: 'main', value: '#F23535' },
        { name: 'Cancel', property: 'btn__cancel', group_name: 'buttons', state: 'main', value: '#095F73' },
        { name: 'Subscribe', property: 'btn__subscribe', group_name: 'buttons', state: 'main', value: '#F23535' },
        { name: 'Social', property: 'btn__social', group_name: 'buttons', state: 'main', value: '#E5E5E5' },
        # toggless
        { name: 'On', property: 'tgl__on', group_name: 'toggless', state: 'main', value: '#F23535' },
        { name: 'Off', property: 'tgl__off', group_name: 'toggless', state: 'main', value: '#FFFFFF' },
        { name: 'Switch Off', property: 'tgl__switch__off', group_name: 'toggless', state: 'main', value: '#A6A6A6' },
        { name: 'Disabled', property: 'tgl__disabled', group_name: 'toggless', state: 'main', value: '#E5E5E5' },
        # typographics
        { name: 'h1', property: 'tp__h1', group_name: 'typographics', state: 'main', value: '#095F73' },
        { name: 'h2', property: 'tp__h2', group_name: 'typographics', state: 'main', value: '#303840' },
        { name: 'h3', property: 'tp__h3', group_name: 'typographics', state: 'main', value: '#303840' },
        { name: 'Main', property: 'tp__main', group_name: 'typographics', state: 'main', value: '#303840' },
        { name: 'Secondary', property: 'tp__secondary', group_name: 'typographics', state: 'main', value: '#6F7073' },
        { name: 'Links hover', property: 'tp__links__hover', group_name: 'typographics', state: 'hover',
          value: '#F23535' },
        { name: 'Labels', property: 'tp__labels', group_name: 'typographics', state: 'main', value: '#A6A6A6' },
        { name: 'Inputs', property: 'tp__inputs', group_name: 'typographics', state: 'main', value: '#6F7073' },
        { name: 'Inputs active', property: 'tp__inputs__active', group_name: 'typographics', state: 'active',
          value: '#303840' },
        { name: 'Inputs validation', property: 'tp__inputs__validation', group_name: 'typographics', state: 'main',
          value: '#FFFFFF' },
        { name: 'Active', property: 'tp__active', group_name: 'typographics', state: 'main', value: '#F23535' },
        { name: 'Disabled', property: 'tp__disabled', group_name: 'typographics', state: 'main', value: '#CCCCCC' },
        { name: 'Icons', property: 'tp__icons', group_name: 'typographics', state: 'main', value: '#A6A6A6' },

        { name: 'Btn main', property: 'tp__btn__main', group_name: 'typographics', state: 'main', value: '#FFFFFF' },
        { name: 'Btn main hover', property: 'tp__btn__main__hover', group_name: 'typographics', state: 'main',
          value: '#FFFFFF' },

        { name: 'Btn secondary', property: 'tp__btn__secondary', group_name: 'typographics', state: 'main',
          value: '#303840' },
        { name: 'Btn secondary hover', property: 'tp__btn__secondary__hover', group_name: 'typographics',
          state: 'main', value: '#303840' },

        { name: 'Btn Tetriary', property: 'tp__btn__tetriary', group_name: 'typographics', state: 'main',
          value: '#303840' },
        { name: 'Btn Tetriary hover', property: 'tp__btn__tetriary__hover', group_name: 'typographics', state: 'main',
          value: '#303840' },

        { name: 'Btn bordered', property: 'tp__btn__bordered', group_name: 'typographics', state: 'main',
          value: '#095F73' },
        { name: 'Btn bordered hover', property: 'tp__btn__bordered__hover', group_name: 'typographics', state: 'main',
          value: '#FFFFFF' },

        { name: 'Bordered', property: 'tp__btn__bordered', group_name: 'buttons', state: 'main', value: '#095F73' },
        { name: 'Btn Bordered hover', property: 'tp__btn__bordered__hover', group_name: 'buttons', state: 'main',
          value: '#095F73' },

        { name: 'Btn Save', property: 'tp__btn__save', group_name: 'buttons', state: 'main', value: '#fff' },
        { name: 'Btn Save hover', property: 'tp__btn__save__hover', group_name: 'buttons', state: 'main',
          value: '#fff' },

        { name: 'Btn Cancel', property: 'tp__btn__cancel', group_name: 'buttons', state: 'main', value: '#fff' },
        { name: 'Btn Cancel hover', property: 'tp__btn__cancel__hover', group_name: 'buttons', state: 'main',
          value: '#fff' },

        { name: 'Btn Subscribe', property: 'tp__btn__subscribe', group_name: 'buttons', state: 'main', value: '#fff' },
        { name: 'Btn Subscribe hover', property: 'tp__btn__subscribe__hover', group_name: 'buttons', state: 'main',
          value: '#fff' },

        { name: 'Btn bordered social', property: 'tp__btn__bordered__social', group_name: 'typographics',
          state: 'main', value: '#095F73' },
        { name: 'Btn bordered social hover', property: 'tp__btn__bordered__social__hover', group_name: 'typographics',
          state: 'main', value: '#095F73' },
        # shadows
        { name: 'Main', property: 'sh__main', group_name: 'shadows', state: 'main', value: '#e6e6e6' },
        { name: 'Secondary', property: 'sh__secondary', group_name: 'shadows', state: 'main', value: '#CCCCCC' },
        { name: 'modals', property: 'sh__modals', group_name: 'shadows', state: 'main', value: '#1A1A1A' },
        # borders
        { name: 'content__sections', property: 'border__content__sections', group_name: 'borders', state: 'main',
          value: 'rgba(9, 95, 115, 0.2)' },
        { name: 'table', property: 'border__table', group_name: 'borders', state: 'main', value: '#F2F2F2' },
        { name: 'separator', property: 'border__separator', group_name: 'borders', state: 'main', value: '#E5E5E5' },
        { name: 'form__normal', property: 'border__form__normal', group_name: 'borders', state: 'main',
          value: '#E6E6E6' },
        { name: 'form__active', property: 'border__form__active', group_name: 'borders', state: 'main',
          value: '#CCCCCC' },
        { name: 'form__error', property: 'border__form__error', group_name: 'borders', state: 'main',
          value: '#FF530D' },
        { name: 'tooltip', property: 'border__tooltip', group_name: 'borders', state: 'main', value: '#E5E5E5' },
        { name: 'toggle__active', property: 'border__toggle__active', group_name: 'borders', state: 'main',
          value: '#CCCCCC' },
        { name: 'toggle__disabled', property: 'border__toggle__disabled', group_name: 'borders', state: 'main',
          value: '#E5E5E5' }
      ]
      white_styles.each do |style|
        theme.system_theme_variables.create(style)
      end
    end
  end
  factory :aa_stub_system_themes, parent: :system_theme
end
