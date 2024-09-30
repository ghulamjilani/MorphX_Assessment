# frozen_string_literal: true
# # Change this to your host. See the readme at https://github.com/lassebunk/dynamic_sitemaps
# # for examples of multiple hosts and folders.
# host ENV['HOST']
# protocol = ENV['PROTOCOL'] || 'https://'
#
# sitemap :site do
#   url root_url, last_mod: Time.now, change_freq: "daily", priority: 1.0
#
#   url Rails.application.class.routes.url_helpers.page_url(ContentPages::HELP_CENTER.parameterize(separator: '-'))
#   url Rails.application.class.routes.url_helpers.page_url(ContentPages::TERMS_CONDITIONS.parameterize(separator: '-'))
#   url Rails.application.class.routes.url_helpers.page_url(ContentPages::PRIVACY_POLICY.parameterize(separator: '-'))
#
#   # # TODO: Presenters logic changed
#   # valid_presenters = Presenter.has_channels
#   # valid_presenters.each do |presenter|
#   #   next if presenter.user.blank?
#   #
#   #   if presenter.user.fake
#   #     # skip it
#   #   else
#   #     if presenter.user.public_display_name.include?('Tim Brown') || presenter.user.public_display_name.include?('Ethos')
#   #       priority = 1
#   #     else
#   #       priority = 0.7
#   #     end
#   #
#   #     url presenter.user.absolute_path, last_mod: presenter.user.updated_at, priority: priority
#   #   end
#   # end
#   #
#   # valid_channels = Channel.approved.not_archived.listed.where(presenter: valid_presenters)
#   # valid_channels.each do |channel|
#   #   if channel.fake
#   #     # skip it
#   #   else
#   #     if channel.title.include?('Ethos') || channel.title.include?('Ethos') || channel.title.include?('Tim Brown')
#   #       priority = 1.0
#   #     else
#   #       priority = 0.7
#   #     end
#   #
#   #     url channel.absolute_path, last_mod: channel.updated_at, priority: priority
#   #   end
#   # end
#   #
#   # Session
#   #   .where(adult: false)
#   #   .where(channel: valid_channels)
#   #   .where(cancelled_at: nil)
#   #   .where(private: false)
#   #   .where(status: Session::Statuses::PUBLISHED).each do |session|
#   #
#   #   if session.fake
#   #     # skip it
#   #   else
#   #     if session.title.include?('Tim Brown')
#   #       priority = 1
#   #     elsif session.featured?
#   #       priority = 0.8
#   #     else
#   #       priority = 0.5
#   #     end
#   #
#   #     url session.absolute_path, last_mod: session.updated_at, priority: priority
#   #   end
#   # end
#
# end
#
# # You can have multiple sitemaps like the above – just make sure their names are different.
#
# # Automatically link to all pages using the routes specified
# # using "resources :pages" in config/routes.rb. This will also
# # automatically set <lastmod> to the date and time in page.updated_at:
# #
# #   sitemap_for Page.scoped
#
# # For products with special sitemap name and priority, and link to comments:
# #
# #   sitemap_for Product.published, name: :published_products do |product|
# #     url product, last_mod: product.updated_at, priority: (product.featured? ? 1.0 : 0.7)
# #     url product_comments_url(product)
# #   end
#
# # If you want to generate multiple sitemaps in different folders (for example if you have
# # more than one domain, you can specify a folder before the sitemap definitions:
# #
# #   Site.all.each do |site|
# #     folder "sitemaps/#{site.domain}"
# #     host site.domain
# #
# #     sitemap :site do
# #       url root_url
# #     end
# #
# #     sitemap_for site.products.scoped
# #   end
#
# # Ping search engines after sitemap generation:
# #
# ping_with "#{protocol}://#{host}/sitemap.xml"
