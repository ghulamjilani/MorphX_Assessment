# frozen_string_literal: true

module SecureRandom
  class << self
    def numeric(length = 8)
      length = 8 if length < 1
      SecureRandom.hex(length).hex.to_s[0..length - 1]
    end
  end
end
