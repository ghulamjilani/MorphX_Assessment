# frozen_string_literal: true

module Mongoid
  class Criteria
    def except(_first, _last)
      self
    end

    def group_values
      []
    end
  end
end
