# frozen_string_literal: true

module ControllerConcerns
  module Shared
    module Authentication
      extend ActiveSupport::Concern

      def signed_in_as_user?(user = nil)
        return false unless user && signed_in?(:user)

        user == warden.user(scope: :user)
      end
    end
  end
end
