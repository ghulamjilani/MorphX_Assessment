# frozen_string_literal: true

module SharingHelper
  def supported_classes
    %w[User Channel Session Video Recording Organization]
  end

  def share_default_message(model)
    case model
    when User
      share_user_default_message(model).squish
    when Channel
      share_channel_default_message(model).squish
    when Session
      share_session_default_message(model).squish
    when Video
      share_session_default_message(model.session).squish
    when Organization
      share_organization_default_message(model).squish
    when Recording
      share_recording_default_message(model).squish
    when Blog::Post
      share_blog_post_default_message(model).squish
    else
      raise "can not share #{model.inspect}"
    end
  end

  def increment_share_counter_path(model, provider)
    shares_increment_path(model: model.class.to_s.downcase, id: model.id, provider: provider)
  end

  # NOTE: "full" means not-shortened URL
  def full_share_url(model)
    if supported_classes.include?(model.class.name)
      if user_signed_in? && current_user.has_owned_channels? && model.organizer == current_user
        model.absolute_path(nil, current_user)
      else
        model.absolute_path
      end

    else
      raise "can not share #{model.inspect}"
    end
  end

  def short_share_url(model)
    if supported_classes.include?(model.class.name)
      if user_signed_in? && current_user.has_owned_channels? && current_user == model.organizer
        model.referral_short_url
      else
        model.short_url
      end
    # path.blank? ? full_share_url(model) : path
    else
      raise "can not share #{model.inspect}"
    end
  end

  def pinterest_share_preview_image_url(model)
    result = model.pinterest_share_preview_image_url
    if result
      uri = URI.parse(result)
      result = image_url(uri.to_s) if uri.host.blank?
      CGI.escape(result)
    else
      nil
    end
  end

  def twitter_handle(model)
    # TODO: add functionality to return twitter slug for user/organization/post/etc after its support is added
    handle = case model.class.to_s
             when 'User'
               model.user_account&.social_links&.twitter&.first&.link.to_s.gsub(
                 %r{^((http(s)?://)?twitter.com/(@)?|@)}, ''
               )
             when 'Organization'
               model.social_links&.twitter&.first&.link.to_s.gsub(%r{^((http(s)?://)?twitter.com/(@)?|@)}, '')
             end
    handle.present? ? "@#{handle}" : nil
  end

  private

  def share_organization_default_message(organization)
    I18n.t 'sharing.organization_default_message_text', organization_name: organization.name
  end

  def share_session_default_message(session)
    I18n.t 'sharing.session_default_message_text', session_title: session.always_present_title
  end

  def share_channel_default_message(channel)
    I18n.t 'sharing.channel_default_message_text', channel_title: channel.title
  end

  def share_user_default_message(_user)
    I18n.t 'sharing.presenter_default_message_text'
  end

  def share_recording_default_message(recording)
    I18n.t 'sharing.session_default_message_text', session_title: recording.title
  end

  def share_blog_post_default_message(blog_post)
    I18n.t 'sharing.blog_post_default_message_text', blog_post_title: blog_post.share_title
  end

  def show_share_video?(share_model)
    @result_video ||= case share_model
                      when Video, Recording
                        true
                      when Session
                        share_model.records.exists?(show_on_profile: true) || !share_model.private?
                      else
                        false
                      end
  end

  def show_share_shop?(share_model)
    @result_shop ||= case share_model
                     when Video, Recording, Session
                       share_model.lists.exists?
                     else
                       false
                     end
  end
end
