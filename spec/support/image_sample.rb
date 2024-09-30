# frozen_string_literal: true

module ImageSample
  @files = {}

  class << self
    # @param size [String] widthxheight
    #   Example: "300x300", "100x50"
    # @return path [String]
    def for_size(size)
      return @files[size].path if @files[size]

      tmp_file = Tempfile.new(size)
      tmp_file.binmode
      img = MiniMagick::Image.open(Rails.root.join('spec/support/1x1.png'))
      img.resize("#{size}!")
      img.write(tmp_file.path)
      @files[size] = tmp_file
      tmp_file.path
    end
  end
end
