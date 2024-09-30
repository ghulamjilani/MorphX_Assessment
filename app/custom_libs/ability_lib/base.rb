# frozen_string_literal: true

module AbilityLib
  class Base
    include CanCan::Ability

    attr_reader :user, :guest, :user_or_guest

    def initialize(user_or_guest)
      case user_or_guest.class.name
      when 'User'
        @user = user_or_guest
      when 'Guest'
        @guest = user_or_guest
      end
      @user ||= User.new
      @guest ||= Guest.new
      @user_or_guest = user_or_guest || @user
      load_permissions
    end

    # supposed to be overridden in child classes
    def load_permissions
    end

    def service_admin_abilities
      @service_admin_abilities ||= {}
    end

    def has_service_admin_ability?(action, subject)
      return false unless (@user.is_a?(User) && @user.service_admin?) || @user.platform_owner?

      service_admin_abilities.key?(action) && service_admin_abilities[action].include?(subject.class)
    end

    def can?(action, subject, attribute = nil, *extra_args)
      has_service_admin_ability?(action.to_sym, subject) || super(action, subject, attribute, extra_args)
    end

    def merge(ability)
      ability.service_admin_abilities.each do |action, subject_classes|
        service_admin_abilities[action] || (@service_admin_abilities[action] = [])
        @service_admin_abilities[action] = [@service_admin_abilities[action], subject_classes].reduce([], :concat)
      end

      super ability
    end
  end
end
