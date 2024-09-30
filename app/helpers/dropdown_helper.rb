# frozen_string_literal: true

module DropdownHelper
  def user_with_avatar(user)
    if user.blank?
      # it is sent by "Immerss", think of it as a system message
      return %(<a class='ensure-link-style avatarImg-MD' style="background-image: url('#{image_url("services/#{Rails.application.credentials.global[:project_name].to_s.downcase}/logo_small.png")}')" ></a>).html_safe
    end

    %(<a href="#{user.relative_path}" class='avatarImg-MD' style="background-image: url('#{user.avatar_url}')"></a>).html_safe
  end

  def sender_data(sender)
    {
      name: sender ? sender.public_display_name : Rails.application.credentials.global[:service_name],
      path: sender ? sender.relative_path : '#',
      avatar: sender ? sender.avatar_url : image_url("services/#{Rails.application.credentials.global[:project_name].to_s.downcase}/favicon.png")
    }
  end
end
