# frozen_string_literal: true

namespace :assets do
  desc 'Upload widget css to s3'
  task upload_additional: :environment do
    view_context = ApplicationController.new.view_context
    public_dir = Rails.root.join('public')
    prefix = Rails.application.config.assets.prefix.dup.tap { |s| s['/'] = '' }
    external_files = [
      'widgets/template_V_L.css',
      'widgets/template_V.css',
      'widgets/template_V_P.css',
      'widgets/template_V_P_L.css',
      'embeds/channel.js',
      'embeds/chromcast.js'
    ]
    external_files.each do |f|
      full_path = public_dir.join(view_context.asset_path(f, host: '')[1..])
      storage_key = "#{prefix}/#{f}"
      ext = File.extname(f)[1..]
      mime = Mime::Type.lookup_by_extension(ext)
      AssetSync
        .storage
        .bucket
        .files
        .create({
                  key: storage_key,
                  body: File.open(full_path, 'r'),
                  public: true,
                  content_type: mime
                })
    end
    # Purge CDN cache for these assets
    # full_urls = external_files.map { |f| view_context.asset_url(f) }
    full_urls = external_files.map { |f| "#{Rails.application.config.action_controller.asset_host}/assets/#{f}" }
    # HighwindsCdn::Purge.purge_url(full_urls)
  end
end
