# frozen_string_literal: true

module StateMachine
  module Integrations
    module ActiveModel
      public :around_validation
    end

    module ActiveRecord
      public :around_save
    end
  end
end
