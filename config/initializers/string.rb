# frozen_string_literal: true

class String
  # replace '\', '|', '/', ',', '.' characters with whitespaces
  def prepare_for_search
    gsub(%r{[\\/|,.\s]+}, ' ')
  end
end
