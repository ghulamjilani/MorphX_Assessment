# frozen_string_literal: true

class CsvDelimiter
  COMMON_DELIMITERS = %w["," ";" "|"].freeze

  def self.find(path)
    first_line = File.open(path).first
    return unless first_line

    snif = {}
    COMMON_DELIMITERS.each do |delim|
      snif[delim] = first_line.count(delim)
    end
    snif = snif.sort { |a, b| b[1] <=> a[1] }

    snif[0][0][1] if snif.size.positive?
  end
end
