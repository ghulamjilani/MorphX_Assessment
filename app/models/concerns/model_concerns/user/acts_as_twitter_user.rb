# frozen_string_literal: true

module ModelConcerns::User::ActsAsTwitterUser
  extend ActiveSupport::Concern

  module ClassMethods
    def connect_to_twitter(payload)
      if (user = Identity.where(provider: payload.provider, uid: payload.uid).first.try(:user))
        user.connect_twitter(payload)

        if user.image.blank? && payload[:info][:image].present?
          i = user.build_image
          i.remote_original_image_url = payload[:info][:image]
          i.save(validate: false)
        end

        user
      end
    end

    def twitter_attributes_to_assign_from_payload(payload)
      if payload.info.name.include?(' ')
        first_name = payload.info.name.split(' ').first
        last_name = payload.info.name.split(' ').last
      else
        first_name = payload.info.name
        last_name = nil
      end

      {
        first_name: first_name,
        last_name: last_name,
        display_name: payload.info.nickname
      }
    end

    def create_from_twitter(payload)
      # {
      #     "provider": "twitter",
      #     "uid": "65395098",
      #     "info": {
      #         "nickname": "nfedyashev",
      #         "name": "Nikita Fedyashev",
      #         "email": "email@example.com", # now we can receive it
      #         "location": "Bishkek-Kyiv",
      #         "image": "http://pbs.twimg.com/profile_images/1538294015/photo_normal.jpg",
      #         "description": "#ruby #OSS #javascript #books #coffee #music",
      #         "urls": {
      #             "Website": null,
      #             "Twitter": "https://twitter.com/nfedyashev"
      #         }
      #     },
      #     "credentials": {
      #         "token": "65395098-NxmSpNnlUxMwFqMozy7dp8GjiC5H5rYiCCuX2Qv3p",
      #         "secret": "yKMHoZQJDa7inosXaWyeh2ljdE2B41zukTtGpSwUlZkBX"
      #     },
      #     "extra": {
      #         "access_token": {
      #             "token": "65395098-NxmSpNnlUxMwFqMozy7dp8GjiC5H5rYiCCuX2Qv3p",
      #             "secret": "yKMHoZQJDa7inosXaWyeh2ljdE2B41zukTtGpSwUlZkBX",
      #             "consumer": {
      #                 "key": "0JjkjWFjsXQSQx1RorJdOg",
      #                 "secret": "jFWBrwW3wWyBpJiVlx89Xaa89M2iTBqupXWMkG6WOA",
      #                 "options": {
      #                     "signature_method": "HMAC-SHA1",
      #                     "request_token_path": "/oauth/request_token",
      #                     "authorize_path": "/oauth/authenticate",
      #                     "access_token_path": "/oauth/access_token",
      #                     "proxy": null,
      #                     "scheme": "header",
      #                     "http_method": "post",
      #                     "oauth_version": "1.0",
      #                     "site": "https://api.twitter.com"
      #                 },
      #                 "http": {
      #                     "address": "api.twitter.com",
      #                     "port": 443,
      #                     "local_host": null,
      #                     "local_port": null,
      #                     "curr_http_version": "1.1",
      #                     "keep_alive_timeout": 2,
      #                     "last_communicated": null,
      #                     "close_on_empty_response": false,
      #                     "socket": null,
      #                     "started": false,
      #                     "open_timeout": 30,
      #                     "read_timeout": 30,
      #                     "continue_timeout": null,
      #                     "debug_output": null,
      #                     "proxy_from_env": true,
      #                     "proxy_uri": null,
      #                     "proxy_address": null,
      #                     "proxy_port": null,
      #                     "proxy_user": null,
      #                     "proxy_pass": null,
      #                     "use_ssl": true,
      #                     "ssl_context": {
      #                         "cert": null,
      #                         "key": null,
      #                         "client_ca": null,
      #                         "ca_file": null,
      #                         "ca_path": null,
      #                         "timeout": null,
      #                         "verify_mode": 0,
      #                         "verify_depth": null,
      #                         "renegotiation_cb": null,
      #                         "verify_callback": null,
      #                         "options": -2147481609,
      #                         "cert_store": null,
      #                         "extra_chain_cert": null,
      #                         "client_cert_cb": null,
      #                         "tmp_dh_callback": null,
      #                         "session_id_context": null,
      #                         "session_get_cb": null,
      #                         "session_new_cb": null,
      #                         "session_remove_cb": null,
      #                         "servername_cb": null
      #                     },
      #                     "ssl_session": {},
      #                     "enable_post_connection_check": true,
      #                     "sspi_enabled": false,
      #                     "ca_file": null,
      #                     "ca_path": null,
      #                     "cert": null,
      #                     "cert_store": null,
      #                     "ciphers": null,
      #                     "key": null,
      #                     "ssl_timeout": null,
      #                     "ssl_version": null,
      #                     "verify_callback": null,
      #                     "verify_depth": null,
      #                     "verify_mode": 0
      #                 },
      #                 "http_method": "post",
      #                 "uri": {
      #                     "scheme": "https",
      #                     "user": null,
      #                     "password": null,
      #                     "host": "api.twitter.com",
      #                     "port": 443,
      #                     "path": "",
      #                     "query": null,
      #                     "opaque": null,
      #                     "registry": null,
      #                     "fragment": null,
      #                     "parser": null
      #                 }
      #             },
      #             "params": {
      #                 "oauth_token": "65395098-NxmSpNnlUxMwFqMozy7dp8GjiC5H5rYiCCuX2Qv3p",
      #                 "oauth_token_secret": "yKMHoZQJDa7inosXaWyeh2ljdE2B41zukTtGpSwUlZkBX",
      #                 "user_id": "65395098",
      #                 "screen_name": "nfedyashev"
      #             },
      #             "response": {
      #                 "cache-control": ["no-cache, no-store, must-revalidate, pre-check=0, post-check=0"],
      #                 "content-length": ["595"],
      #                 "content-type": ["application/json;charset=utf-8"],
      #                 "date": ["Fri, 31 Jan 2014 07:31:23 GMT"],
      #                 "expires": ["Tue, 31 Mar 1981 05:00:00 GMT"],
      #                 "last-modified": ["Fri, 31 Jan 2014 07:31:23 GMT"],
      #                 "pragma": ["no-cache"],
      #                 "server": ["tfe"],
      #                 "set-cookie": ["lang=en", "guest_id=v1%3A139115348330522845; Domain=.twitter.com; Path=/; Expires=Sun, 31-Jan-2016 07:31:23 UTC"],
      #                 "status": ["200 OK"],
      #                 "strict-transport-security": ["max-age=631138519"],
      #                 "x-access-level": ["read-write"],
      #                 "x-content-type-options": ["nosniff"],
      #                 "x-frame-options": ["SAMEORIGIN"],
      #                 "x-rate-limit-limit": ["15"],
      #                 "x-rate-limit-remaining": ["14"],
      #                 "x-rate-limit-reset": ["1391154383"],
      #                 "x-transaction": ["24981d7567abfb83"],
      #                 "x-xss-protection": ["1; mode=block"],
      #                 "connection": ["close"]
      #             }
      #         },
      #         "raw_info": {
      #             "id": 65395098,
      #             "id_str": "65395098",
      #             "name": "Nikita Fedyashev",
      #             "screen_name": "nfedyashev",
      #             "location": "Bishkek-Kyiv",
      #             "description": "#ruby #OSS #javascript #books #coffee #music",
      #             "url": null,
      #             "entities": {
      #                 "description": {
      #                     "urls": [
      #
      #                     ]
      #                 }
      #             },
      #             "protected": false,
      #             "followers_count": 168,
      #             "friends_count": 699,
      #             "listed_count": 14,
      #             "created_at": "Thu Aug 13 15:58:27 +0000 2009",
      #             "favourites_count": 1276,
      #             "utc_offset": 21600,
      #             "time_zone": "Almaty",
      #             "geo_enabled": true,
      #             "verified": false,
      #             "statuses_count": 4541,
      #             "lang": "en",
      #             "contributors_enabled": false,
      #             "is_translator": false,
      #             "is_translation_enabled": false,
      #             "profile_background_color": "C0DEED",
      #             "profile_background_image_url": "http://a0.twimg.com/profile_background_images/131076632/09original.gif",
      #             "profile_background_image_url_https": "https://si0.twimg.com/profile_background_images/131076632/09original.gif",
      #             "profile_background_tile": true,
      #             "profile_image_url": "http://pbs.twimg.com/profile_images/1538294015/photo_normal.jpg",
      #             "profile_image_url_https": "https://pbs.twimg.com/profile_images/1538294015/photo_normal.jpg",
      #             "profile_link_color": "0084B4",
      #             "profile_sidebar_border_color": "C0DEED",
      #             "profile_sidebar_fill_color": "DDEEF6",
      #             "profile_text_color": "333333",
      #             "profile_use_background_image": true,
      #             "default_profile": false,
      #             "default_profile_image": false,
      #             "following": false,
      #             "follow_request_sent": false,
      #             "notifications": false,
      #             "email": "email@example.com" # now we can receive it
      #         }
      #     }
      # }

      user = new
      user.attributes = twitter_attributes_to_assign_from_payload(payload)
      user.tzinfo = payload.tzinfo

      if payload.info.email.present?
        user.email = payload.info.email

        user.skip_validation_for(*all_validation_skipable_user_attributes.dup.reject { |s| s == :email })
      else
        user.skip_validation_for(*all_validation_skipable_user_attributes)
      end
      user.before_create_generic_callbacks_without_skipping_validation

      # otherwise it is treated as confirmed account despite blank email
      if user.email.present?
        user.skip_confirmation!
      end
      # Skip password validation
      def user.password_required?
        false
      end

      user.save!

      user.identities.create!(provider: payload.provider,
                              uid: payload.uid,
                              token: payload.credentials.token,
                              secret: payload.credentials.secret)

      if user.image.blank? && payload[:info][:image].present?
        i = user.build_image
        i.remote_original_image_url = payload[:info][:image]
        i.save(validate: false)
      end

      user
    end
  end
end
