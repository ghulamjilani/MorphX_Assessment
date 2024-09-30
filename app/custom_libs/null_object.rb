# frozen_string_literal: true

class NullObject
  def method_missing(*_args)
    nil
  end
end
