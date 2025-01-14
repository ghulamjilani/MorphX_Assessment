# frozen_string_literal: true

if defined?(AssetSync)
  AssetSync.configure do |config|
    config.fog_provider = 'AWS'
    config.fog_directory = ENV['S3_BUCKET']
    config.aws_access_key_id = ENV['S3_ACCESS_KEY_ID']
    config.aws_secret_access_key = ENV['S3_SECRET_ACCESS_KEY']
    # To use AWS reduced redundancy storage.
    # config.aws_reduced_redundancy = true
    #
    # Change AWS signature version. Default is 4
    # config.aws_signature_version = 4
    #
    # Change host option in fog (only if you need to)
    config.fog_host = 's3-us-west-2.amazonaws.com'
    #
    # Use http instead of https. Default should be "https" (at least for fog-aws)
    # config.fog_scheme = "http"

    # Invalidate a file on a cdn after uploading files
    # config.cdn_distribution_id = "12345"
    # config.invalidate = ['file1.js']

    # Increase upload performance by configuring your region
    config.fog_region = if Rails.env.development?
                          'us-east-1'
                        else
                          'us-west-2'
                        end
    # config.aws_iam_roles = true
    #
    # Don't delete files from the store
    # config.existing_remote_files = "keep"
    #
    # Automatically replace files with their equivalent gzip compressed version
    # config.gzip_compression = true
    #
    # Use the Rails generated 'manifest.yml' file to produce the list of files to
    # upload instead of searching the assets directory.
    # config.manifest = true
    #
    # Upload the manifest file also.
    # config.include_manifest = false
    #
    # Fail silently.  Useful for environments such as Heroku
    # config.fail_silently = true
    #
    # Log silently. Default is `true`. But you can set it to false if more logging message are preferred.
    # Logging messages are sent to `STDOUT` when `log_silently` is falsy
    # config.log_silently = true
    #
    # Allow custom assets to be cacheable. Note: The base filename will be matched
    # If you have an asset with name `app.0ba4d3.js`, only `app.0ba4d3` will need to be matched
    # config.cache_asset_regexps = [ /\.[a-f0-9]{8}$/i, /\.[a-f0-9]{20}$/i ]
    # config.cache_asset_regexp = /\.[a-f0-9]{8}$/i
  end
end
