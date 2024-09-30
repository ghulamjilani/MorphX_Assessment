# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0.1'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
# Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

Rails.application.config.assets.enabled = true
Rails.application.config.assets.logger = Logger.new $stdout
Rails.application.config.assets.initialize_on_precompile = true
# Rails.application.config.assets.precompile << /\.(?:svg|eot|woff|ttf)$/
# Rails.application.config.assets.precompile += %w(
#                                    chatcss/custom.css
#                                    home.js
#                                    jquery.js
#                                    respond.js
#                                    video_client/core.css
#                                    video_client/core.js
#                                    video_page/vidyo/vidyo.client.messages.js
#                                    video_page/webrtc84/vidyo.client.js
#                                    video_page/webrtc84/vidyo.client.messages.js
#                                    video_page/webrtc84/vidyo.client.private.messages.js
#                                    video_client/videoapplication.js
#                                    video_client/webrtcapplication.js
#                                    video_client/vidyo_io.js
#                                    widgets/core.css
#                                    widgets/template_V.css
#                                    widgets/template_V_P.css
#                                    widgets/template_V_L.css
#                                    widgets/template_V_P_L.css
#                                    css/partials/_NOT_GLOBAL_aos.css
#                                    views/widgets/player.js
#                                    views/widgets/additions.js
#                                    views/widgets/shop.js
#                                    aos.js
#                                    embeds/channel.js
#                                    embeds/chromcast.js
#                                    views/widgets/chat_with_dependencies.js
#                                    pages/studios.js
#     )

Rails.application.config.assets.precompile += %w[immerss_kss.css immerss_kss.js] unless Rails.env.production?
Rails.application.config.assets.precompile += %w[manifest.json]
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
end