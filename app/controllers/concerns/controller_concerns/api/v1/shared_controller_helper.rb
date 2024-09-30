# frozen_string_literal: true

module ControllerConcerns
  module Api
    module V1
      module SharedControllerHelper
        extend ActiveSupport::Concern

        module ClassMethods
          def skip_authorization
            skip_before_action :authorization
          end

          def optional_authorization
            skip_before_action :authorization, unless: -> { request.headers['Authorization'].present? }
          end

          AUTHORIZATION_TYPES = %w[organization user guest user_or_guest].freeze

          AUTHORIZATION_TYPES.each do |type|
            define_method("skip_#{type}_authorization") do
              skip_before_action "authorization_only_for_#{type}".to_sym
            end

            define_method("optional_#{type}_authorization") do
              skip_before_action "authorization_only_for_#{type}".to_sym, unless: -> { request.headers['Authorization'].present? }
            end
          end
        end

        included do
          helper_method :organization_default_user_path
        end

        def organization_default_user_path(organization)
          if (default_channel = organization.default_user_channel(current_user))
            return default_channel.relative_path
          end

          organization.relative_path
        end

        def request_ip_address
          request.headers['HTTP_CF_CONNECTING_IP'] || request.headers['HTTP_X_FORWARDED_FOR'] || request.remote_ip
        end
      end
    end
  end
end
