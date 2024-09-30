# frozen_string_literal: true

# require 'google/apis/oauth2_v2'
module ControllerConcerns::MobileSocialsValidator
  extend ActiveSupport::Concern
  # {
  #     "provider": "gplus",
  #     "uid": "110339737937790001686",
  #     "info": {
  #         "name": "Max Dolgih",
  #         "email": "maxim.dolgih@gmail.com",
  #         "first_name": "Max",
  #         "last_name": "Dolgih",
  #         "image": "https://lh3.googleusercontent.com/-XdUIqdMkCWA/AAAAAAAAAAI/AAAAAAAAAAA//photo.jpg",
  #         "urls": {
  #             "Google": "https://plus.google.com/11033973793"
  #         }
  #     },
  #     "credentials": {
  #         "token": "ya29.GlsNBe5D8G6rd7VdXorRiTiDQ-A5W1xfaYew7GWOuzBaVHiqr0J4BOgVdDwtPA8hLY1kkbYTypU_fvvrk3vm_85hxn9NfQEmx_TZVaFk8en5Wk",
  #         "refresh_token": "3Ofyz19nPA1yLZ7demEtC6JdVE",
  #         "expires_at": 1514532,
  #         "expires": true
  #     },
  #     "extra": {
  #         "id_token": "eyJRkMWU1ZTEwOWFmZGYifQ.eyJhenAiOiLCJlbWFpbCI6Im1heGltLmRvbGdpaEBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiYXRfaGFzaCI6IkNuZnB6VTdjX1FqVWVha2g5M3h3RF0IjoxNTExNDAwOTMyLCJleHAiOjE1MTE0MDQ1MzJ9.ZrCof_DL5zWeyKzQRjojLPHUv_daOiqYIvOH2cLsylyWRvCN5l9zJgfWyiGYePgfqixcNm-fasRsodXhxE_T2xO8M_I5UCSPJ2kXzeiyl3RQ2lV7xZ5Iz7qZaHVjzvR-Tg59d-12ayHDhzr6zY7w0g0Qc61g",
  #         "id_info": {
  #             "azp": "712653361354.apps.googleusercontent.com",
  #             "aud": "712653361354.apps.googleusercontent.com",
  #             "sub": "110339737937790001686",
  #             "email": "maxim.dolgih@gmail.com",
  #             "email_verified": true,
  #             "at_hash": "CnfpzQ93xwDQ",
  #             "iss": "accounts.google.com",
  #             "iat": 1511400932,
  #             "exp": 1511404532
  #         },
  #         "raw_info": {
  #             "kind": "plus#personOpenIdConnect",
  #             "gender": "male",
  #             "sub": "1103397379376",
  #             "name": "Max Dolgih",
  #             "given_name": "Max",
  #             "family_name": "Dolgih",
  #             "profile": "https://plus.google.com/11033973793776",
  #             "picture": "https://lh3.googleusercontent.com/-XdUIqdMkCWA/AAAAAAAAAAI/AAAAAAAAAAA/photo.jpg?sz=50",
  #             "email": "maxim.dolgih@gmail.com",
  #             "email_verified": "true",
  #             "locale": "ru"
  #         }
  #     }
  # }

  def empty_playload
    hash = {
      verify: false,
      message: 'Wrong social',
      provider: nil,
      uid: nil,
      info: OpenStruct.new({
                             name: nil,
                             email: nil,
                             first_name: nil,
                             last_name: nil,
                             image: nil,
                             urls: {
                               Google: nil
                             }
                           }),
      credentials: OpenStruct.new({
                                    token: nil,
                                    refresh_token: nil,
                                    expires_at: nil,
                                    expires: nil
                                  }),
      extra: OpenStruct.new({
                              id_token: nil,
                              id_info: OpenStruct.new({
                                                        azp: nil,
                                                        aud: nil,
                                                        sub: nil,
                                                        email: nil,
                                                        email_verified: nil,
                                                        at_hash: nil,
                                                        iss: nil,
                                                        iat: nil,
                                                        exp: nil
                                                      }),
                              raw_info: OpenStruct.new({
                                                         kind: nil,
                                                         gender: nil,
                                                         sub: nil,
                                                         name: nil,
                                                         given_name: nil,
                                                         family_name: nil,
                                                         profile: nil,
                                                         picture: nil,
                                                         email: nil,
                                                         email_verified: nil,
                                                         locale: nil
                                                       })
                            })
    }
    OpenStruct.new(hash)
  end

  # tokeninfo
  # => #<Google::Apis::Oauth2V2::Tokeninfo:0x007faf04b2e4a8 @access_type="offline", @audience="871935708351-jpv9u3phlm8b0g0bvt69vd3ouqjapia8.apps.googleusercontent.com", @expires_in=701, @issued_to="871935708351-jpv9u3phlm8b0g0bvt69vd3ouqjapia8.apps.googleusercontent.com", @scope="https://www.googleapis.com/auth/plus.login https://www.googleapis.com/auth/plus.me https://www.googleapis.com/auth/plus.circles.members.read https://www.googleapis.com/auth/plus.profile.agerange.read https://www.googleapis.com/auth/plus.profile.language.read https://www.googleapis.com/auth/plus.moments.write https://www.googleapis.com/auth/userinfo.profile", @user_id="110339737937790001686">

  # userinfo
  # @family_name="Dolgih",
  # @gender="male",
  # @given_name="Max",
  # @id="11033973793776",
  # @link="https://plus.google.com/11033973793776",
  # @locale="ru",
  # @name="Max Dolgih",
  # @picture=
  #     "https://lh3.googleusercontent.com/-XdUIqdMkCWA/AAAAAAAAAAI/AAAAAAAAAAAphoto.jpg">

  def verify_google(params)
    playload = empty_playload
    playload.provider = 'gplus'

    begin
      # client = Google::Apis::Oauth2V2::Oauth2Service.new
      # #token_info = client.tokeninfo(id_token: params[:id_token])
      response = Excon.get('https://www.googleapis.com/oauth2/v3/tokeninfo',
                           query: { id_token: params[:id_token] })
      token_info = OpenStruct.new(JSON.parse(response[:body]))

      if token_info.aud == ENV['GPLUS_CLIENT_ID']
        playload.verify = true
        playload.uid = token_info.sub
        playload.info.name = token_info.name
        playload.info.email = token_info.email
        playload.info.first_name = token_info.given_name
        playload.info.last_name = token_info.family_name
        playload.info.image = token_info.picture
        playload.info.urls = {}
        playload.credentials.token = params[:access_token]
        playload.credentials.refresh_token = params[:refresh_token]
        playload.credentials.expires_at = Time.at(token_info.exp.to_i)
        playload.credentials.expires = !!token_info.expires_in
      else
        playload.message = "Wrong app #{token_info.aud}"
      end
      playload
    rescue StandardError => e
      Airbrake.notify(e)
      playload.message = e.message
      playload
    end
  end

  def verify_facebook(params)
    playload = empty_playload
    playload.provider = 'facebook'

    begin
      api = Koala::Facebook::API.new(params[:access_token])
      user_info, token_info = api.batch do |batch_api|
        batch_api.get_object('me?fields=id,email,name,first_name,last_name,gender')
        batch_api.get_object("debug_token?input_token=#{params[:access_token]}&access_token=#{ENV['FACEBOOK_APP_ID']}|#{ENV['FACEBOOK_APP_SECRET']}")
      end

      if !token_info.is_a?(Hash) && token_info.fb_error_message.present?
        playload.message = token_info.fb_error_message
        return playload
      end

      if token_info['data'].present? && token_info['data']['app_id'] == ENV['FACEBOOK_APP_ID'] && token_info['data']['is_valid'] == true
        playload.verify = true
        playload.uid = user_info['id']
        playload.extra.raw_info.gender = user_info['gender']
        playload.extra.raw_info.first_name = user_info['first_name']
        playload.extra.raw_info.last_name  = user_info['last_name']
        playload.extra.raw_info.name = user_info['name']
        playload.info.name = user_info['name']
        playload.info.email = user_info['email']
        playload.info.first_name = user_info['first_name']
        playload.info.last_name = user_info['last_name']
        playload.credentials.token = params[:access_token]
        playload.credentials.refresh_token = params[:refresh_token]
        playload.credentials.expires_at = token_info['data']['expires_at']
        playload.credentials.expires = !!token_info['data']['expires_at']
      else
        playload.message = "Error app or token not valid #{token_info['data']}"
      end
      playload
    rescue StandardError => e
      Airbrake.notify(e)
      playload.message = e.message
      playload
    end
  end

  # https://stackoverflow.com/questions/29728109/linkedin-mobile-access-token-for-making-server-side-rest-api-calls
  #=> #<OpenStruct emailAddress=“v.gushek@gmail.com”, firstName=“Victor”, id=“EuuOfHDr9h”, lastName=“Gushek”, pictureUrl=“https://media.licdn.com/mpr/mprx/0_2weeFywkkw6bdujBmDoUF0JQkmrbWEjBmEycF0VJUHXBnaoc8SZkWxmcE_KZoSpUDeEnHZe4NAo8“>
  # payload.inspect
  #=> {"provider" => "linkedin",
  # "uid" => "u3Tm-BPoe_",
  # "info"=>
  #  {"name" => "Nikita Fedyashev",
  #   "email" => "nfedyashev@gmail.com",
  #   "nickname" => "Nikita Fedyashev",
  #   "first_name" => "Nikita",
  #   "last_name" => "Fedyashev",
  #   "location"=>nil,
  #   "description"=>nil,
  #   "image"=>
  #    "http://m.c.lnkd.licdn.com/mpr/mprx/0_x9J4Kt9SerQuyfFtgnUwKAlTelATpfntjADbKAnPBcLliwT-1rdqOlGgQylYxHBYYzR6xnH7OLin",
  #   "phone"=>nil,
  #   "headline"=>nil,
  #   "industry"=>nil,
  #   "urls"=>{"public_profile" => "http://www.linkedin.com/in/nfedyashev"}},
  # "credentials"=>
  #  {"token" => "f33f5f4c-bad1-4ebe-a65b-5ff9391a08aa",
  #   "secret" => "c0fe6fef-75dc-43ab-857d-be479b881f5a"},
  # "extra"=>
  def verify_linkedin(params)
    playload = empty_playload
    playload.provider = 'linkedin'

    begin
      response = Excon.get('https://api.linkedin.com/v1/people/~:(id,first-name,last-name,formatted-name,picture-url,location,email-address)',
                           query: { format: :json },
                           headers: {
                             'Authorization' => "Bearer #{params[:access_token]}",
                             'x-li-src' => 'msdk'
                           })
      user_info = OpenStruct.new(JSON.parse(response[:body]))

      if user_info.id && user_info.emailAddress
        playload.verify = true
        playload.uid = user_info.id
        playload.info.name = user_info.formattedName
        playload.info.email = user_info.emailAddress
        playload.info.first_name = user_info.firstName
        playload.info.last_name = user_info.lastName
        playload.info.image = user_info.pictureUrl
        playload.info.urls = {}
        playload.credentials.token = params[:access_token]
        playload.credentials.expires_at = Time.at(params[:expires_at].to_i / 1000)
        playload.credentials.expires = !!params[:expires_at]
      else
        playload.message = "Error #{user_info}"
      end
      playload
    rescue StandardError => e
      Airbrake.notify(e)
      playload.message = e.message
      playload
    end
  end

  def verify_twitter(params)
    playload = empty_playload
    playload.provider = 'twitter'

    begin
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
        config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
        config.access_token        = params[:access_token]
        config.access_token_secret = params[:access_token_secret]
      end
      response = Twitter::REST::Request.new(
        client,
        :get, 'https://api.twitter.com/1.1/account/verify_credentials.json',
        include_email: true,
        include_entities: false
      ).perform
      # response => {:id=>2209348868, :id_str=>"2209348868", :name=>"Son Hekayem :((", :screen_name=>"AXumar", :location=>":((", :description=>"Sevdiyime Nifret ediremm", :url=>nil, :entities=>{:description=>{:urls=>[]}}, :protected=>true, :followers_count=>462, :friends_count=>1600, :listed_count=>1, :created_at=>"Fri Nov 22 18:06:10 +0000 2013", :favourites_count=>142, :utc_offset=>7200, :time_zone=>"Kyiv", :geo_enabled=>false, :verified=>false, :statuses_count=>442, :lang=>"ru", :status=>{:created_at=>"Fri Dec 05 16:18:06 +0000 2014", :id=>540902947949785088, :id_str=>"540902947949785088", :text=>"Soyuq olma sense hava http://t.co/hK9HBlyam2", :truncated=>false, :extended_entities=>{:media=>[{:id=>540902946255302656, :id_str=>"540902946255302656", :indices=>[22, 44], :media_url=>"http://pbs.twimg.com/media/B4GsXSGCcAAK_2d.jpg", :media_url_https=>"https://pbs.twimg.com/media/B4GsXSGCcAAK_2d.jpg", :url=>"http://t.co/hK9HBlyam2", :display_url=>"pic.twitter.com/hK9HBlyam2", :expanded_url=>"https://twitter.com/AXumar/status/540902947949785088/photo/1", :type=>"photo", :sizes=>{:thumb=>{:w=>150, :h=>150, :resize=>"crop"}, :large=>{:w=>603, :h=>604, :resize=>"fit"}, :medium=>{:w=>603, :h=>604, :resize=>"fit"}, :small=>{:w=>603, :h=>604, :resize=>"fit"}}}]}, :source=>"<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>", :in_reply_to_status_id=>nil, :in_reply_to_status_id_str=>nil, :in_reply_to_user_id=>nil, :in_reply_to_user_id_str=>nil, :in_reply_to_screen_name=>nil, :geo=>nil, :coordinates=>nil, :place=>nil, :contributors=>nil, :is_quote_status=>false, :retweet_count=>0, :favorite_count=>1, :favorited=>false, :retweeted=>false, :possibly_sensitive=>false, :lang=>"tr"}, :contributors_enabled=>false, :is_translator=>false, :is_translation_enabled=>false, :profile_background_color=>"FFF04D", :profile_background_image_url=>"http://abs.twimg.com/images/themes/theme19/bg.gif", :profile_background_image_url_https=>"https://abs.twimg.com/images/themes/theme19/bg.gif", :profile_background_tile=>false, :profile_image_url=>"http://pbs.twimg.com/profile_images/536932277251371008/xmIXWsF6_normal.jpeg", :profile_image_url_https=>"https://pbs.twimg.com/profile_images/536932277251371008/xmIXWsF6_normal.jpeg", :profile_banner_url=>"https://pbs.twimg.com/profile_banners/2209348868/1416849952", :profile_link_color=>"0099CC", :profile_sidebar_border_color=>"FFF8AD", :profile_sidebar_fill_color=>"F6FFD1", :profile_text_color=>"333333", :profile_use_background_image=>true, :has_extended_profile=>false, :default_profile=>false, :default_profile_image=>false, :following=>false, :follow_request_sent=>false, :notifications=>false, :translator_type=>"none"}
      user_info = OpenStruct.new(response)

      if user_info.id && user_info.email
        playload.verify = true
        playload.uid = user_info.id
        playload.info.name = user_info.screen_name
        playload.info.email = user_info.email
        playload.info.first_name = user_info.name
        playload.info.last_name =
          playload.info.image = user_info.profile_image_url_https.to_s.gsub('_normal', '')
        playload.info.urls = {}
        playload.credentials.token = params[:access_token]
        playload.credentials.secret = params[:access_token_secret]
      else
        playload.message = 'Email is blank'
      end
      playload
    rescue StandardError => e
      Airbrake.notify(e)
      playload.message = e.message
      playload
    end
  end

  # TODO: write this
  def verify_instagram(_params)
    playload = empty_playload
    playload.provider = 'instagram'
    playload
  end

  # resp = Excon.get('https://appleid.apple.com/auth/keys')
  # pp JSON.parse(resp.body)
  # {"keys"=>
  #   [{"kty"=>"RSA",
  #     "kid"=>"86D88Kf",
  #     "use"=>"sig",
  #     "alg"=>"RS256",
  #     "n"=>
  #      "iGaLqP6y-SJCCBq5Hv6pGDbG_SQ11MNjH7rWHcCFYz4hGwHC4lcSurTlV8u3avoVNM8jXevG1Iu1SY11qInqUvjJur--hghr1b56OPJu6H1iKulSxGjEIyDP6c5BdE1uwprYyr4IO9th8fOwCPygjLFrh44XEGbDIFeImwvBAGOhmMB2AD1n1KviyNsH0bEB7phQtiLk-ILjv1bORSRl8AK677-1T8isGfHKXGZ_ZGtStDe7Lu0Ihp8zoUt59kx2o9uWpROkzF56ypresiIl4WprClRCjz8x6cPZXU2qNWhu71TQvUFwvIvbkE1oYaJMb0jcOTmBRZA2QuYw-zHLwQ",
  #     "e"=>"AQAB"},
  #    {"kty"=>"RSA",
  #     "kid"=>"eXaunmL",
  #     "use"=>"sig",
  #     "alg"=>"RS256",
  #     "n"=>
  #      "4dGQ7bQK8LgILOdLsYzfZjkEAoQeVC_aqyc8GC6RX7dq_KvRAQAWPvkam8VQv4GK5T4ogklEKEvj5ISBamdDNq1n52TpxQwI2EqxSk7I9fKPKhRt4F8-2yETlYvye-2s6NeWJim0KBtOVrk0gWvEDgd6WOqJl_yt5WBISvILNyVg1qAAM8JeX6dRPosahRVDjA52G2X-Tip84wqwyRpUlq2ybzcLh3zyhCitBOebiRWDQfG26EH9lTlJhll-p_Dg8vAXxJLIJ4SNLcqgFeZe4OfHLgdzMvxXZJnPp_VgmkcpUdRotazKZumj6dBPcXI_XID4Z4Z3OM1KrZPJNdUhxw",
  #     "e"=>"AQAB"}]}
  #
  #
  # JWT.decode(token, nil, false)
  # => [{"iss"=>"https://appleid.apple.com", "aud"=>"live.unite.unite.ios", "exp"=>1593527938, "iat"=>1593527338, "sub"=>"000150.4af5520061d04f20952d29c1c6f9ea1a.2313", "c_hash"=>"ZrLzkrM-NNwR6a7UNvKdXw", "email"=>"v.gushek@gmail.com", "email_verified"=>"true", "auth_time"=>1593527338, "nonce_supported"=>true}, {"kid"=>"eXaunmL", "alg"=>"RS256"}]
  # params
  # first_name
  # last_name
  # token
  def verify_apple(params)
    playload = empty_playload
    playload.provider = 'apple'

    token = params[:token]
    token_decoded = JWT.decode(token, nil, false)[1]

    resp = Excon.get('https://appleid.apple.com/auth/keys')
    jwk_key = JSON.parse(resp.body)['keys'].find do |item|
      item['kid'] == token_decoded['kid'] && item['alg'] == token_decoded['alg']
    end
    raise 'jwk_key nil' if jwk_key.nil?

    token_verified = JWT.decode(token, JWK::RSAKey.new(jwk_key).to_openssl_key, true, { algorithm: jwk_key['alg'] })[0]
    playload.uid = token_verified['sub']
    playload.info.email = token_verified['email']
    playload.info.first_name = params[:first_name]
    playload.info.last_name = params[:last_name]

    playload.verify = true
    playload
  rescue StandardError => e
    Airbrake.notify(e)
    playload.message = e.message
    playload
  end

  def verify_zoom(_params)
    playload = empty_playload
    playload.provider = 'zoom'
    playload
  end
end
