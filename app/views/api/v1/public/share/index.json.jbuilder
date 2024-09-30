# frozen_string_literal: true

envelope json, (@status || 200), (@share_model.pretty_errors if @share_model.errors.present?) do
  json.cache! [@share_model, current_user], expires_in: 1.day do
    json.model do
      json.facebook_url "https://www.facebook.com/sharer.php?u=#{@share_model.absolute_path}"
      json.twitter_url "https://twitter.com/intent/tweet?url=#{@share_model.absolute_path}&text=#{@share_model.share_title}"
      json.linkedin_url "https://www.linkedin.com/shareArticle?mini=true&url=#{@share_model.absolute_path}&title=#{@share_model.share_title}&summary=#{@share_model.share_description}&source=#{Rails.application.credentials.global[:host]}"
      json.pinterest_url "http://pinterest.com/pin/create/button/?url=#{@share_model.absolute_path}&description=#{@share_model.share_title}&media=#{@share_model.share_image_url}"
      json.tumblr_url "https://www.tumblr.com/widgets/share/tool?canonicalUrl=#{@share_model.absolute_path}"
      json.reddit_url "https://ssl.reddit.com/submit?url=#{@share_model.absolute_path}&title=#{@share_model.share_title}"
      json.increment_share_counter_url shares_increment_url(model: @share_model.class.to_s, id: @share_model.id)
      json.full_permalink @share_model.absolute_path
      json.short_permalink @share_model.short_url
      if current_user.present?
        json.referral_permalink @share_model.absolute_path(
          UTM.build_params({ utm_content: current_user.utm_content_value }), current_user
        )
        json.mail_body "#{share_default_message(@share_model)}\n #{CGI.unescape(@share_model.absolute_path)}".squish
        json.mail_subject "#{current_user.public_display_name} shared a #{@share_model.class.to_s.downcase} with you on #{Rails.application.credentials.global[:service_name]}."
      end
    end
  end
end
