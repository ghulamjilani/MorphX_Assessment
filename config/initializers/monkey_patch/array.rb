# frozen_string_literal: true

class Array
  def human_sort
    sort_by do |item|
      item = yield(item) if block_given?
      item.to_s.split(/(\d+)/).map { |e| [e.to_i, e] }
    end
  end
end
