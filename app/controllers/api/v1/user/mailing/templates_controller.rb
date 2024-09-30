# frozen_string_literal: true

module Api
  module V1
    module User
      module Mailing
        class TemplatesController < Api::V1::User::Mailing::ApplicationController
          def index
            @templates = ::Mailing::Template::BASIC
          end
        end
      end
    end
  end
end
