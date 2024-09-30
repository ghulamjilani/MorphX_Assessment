# frozen_string_literal: true

module Immerss
  class JoinHelperProxy < ActionView::Base
    include JoinHelper

    def initialize(current_user)
      @current_user = current_user
      @current_ability = AbilityLib::Legacy::Ability.new(current_user)
    end

    attr_reader :current_user

    def can?(action, subject, *extra_args)
      @current_ability.can?(action, subject, extra_args)
    end

    def browser
      @browser ||= begin
        string = UserAgent
                 .where(user_id: @current_user.id)
                 .order(last_time_used_at: :desc)
                 .first
                 .try(:value)

        Browser.new(string || '')
      end
    end

    def modern_browser?
      b = browser
      [
        b.chrome?('>= 65'),
        b.safari?('>= 10'),
        b.firefox?('>= 52'),
        b.ie?('>= 11') && !b.compatibility_view?,
        b.edge?('>= 15'),
        b.opera?('>= 50'),
        b.uc_browser?,
        b.device.samsung?,
        b.facebook? && b.safari_webapp_mode? && b.webkit_full_version.to_i >= 602
      ].any?
    end
  end
end
