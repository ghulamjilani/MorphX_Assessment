# frozen_string_literal: true

module Sales::Affiliate
  class Partner
    def name
      self.class::NAME
    end
  end
end
