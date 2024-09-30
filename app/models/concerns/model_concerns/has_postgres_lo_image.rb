# frozen_string_literal: true

module ModelConcerns::HasPostgresLoImage
  extend ActiveSupport::Concern

  # see 35e4e874764047875891c10225df741b77a8e553 if ever decide to uncomment it
  # no implicit conversion of nil into String
  # /Users/nfedyashev/.rbenv/versions/2.2.0/lib/ruby/gems/2.2.0/gems/carrierwave-0.10.0/lib/carrierwave/uploader/cache.rb:84:in `basename'
  # /Users/nfedyashev/.rbenv/versions/2.2.0/lib/ruby/gems/2.2.0/gems/carrierwave-0.10.0/lib/carrierwave/uploader/cache.rb:84:in `sanitized_file'
  # /Users/nfedyashev/.rbenv/versions/2.2.0/lib/ruby/gems/2.2.0/gems/carrierwave-0.10.0/lib/carrierwave/uploader/cache.rb:116:in `cache!'
  # /Users/nfedyashev/.rbenv/versions/2.2.0/lib/ruby/gems/2.2.0/gems/carrierwave-0.10.0/lib/carrierwave/uploader/versions.rb:226:in `recreate_versions!'
  # /Users/nfedyashev/.rbenv/versions/2.2.0/lib/ruby/gems/2.2.0/bundler/gems/carrierwave_backgrounder-0f75d61c3453/lib/backgrounder/workers/process_asset.rb:12:in `perform'
  # /Users/nfedyashev/.rbenv/versions/2.2.0/lib/ruby/gems/2.2.0/bundler/gems/carrierwave_backgrounder-0f75d61c3453/lib/backgrounder/workers/base.rb:6:in `perform'
  # process_in_background :image # doesn't seem to work anymore and causes TypeError: no implicit conversion of nil into String

  # def try_remove_image(attribute_name = :image)
  #   connection = ActiveRecord::Base.connection.raw_connection
  #
  #   #NOTE - rescuing because for some strange reason sometimes it tries to unlink identifier twice(which causes PG::Error: lo_unlink failed)
  #   #       we basically care only about ChannelImage removal because it is not needed without #image
  #   begin
  #     #overrides carrierwave-postgresql/lib/carrierwave/storage/postgresql_lo.rb#delete because
  #     # connection.lo_unlink(image)
  #     #TypeError: no implicit conversion of ChannelImageUploader into Integer
  #
  #     #> read_attribute(:image)
  #     #> 152679
  #
  #     image_lo_id = read_attribute(attribute_name.to_sym)
  #
  #     return true if image_lo_id.nil?
  #
  #     connection.lo_unlink image_lo_id
  #   rescue PG::Error => e
  #     Rails.logger.warn e.message
  #   end
  #   true
  # end
end
