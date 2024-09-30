# frozen_string_literal: true

module SpaPathsHelper
  def organization_absolute_url(organization)
    "#{ENV['PROTOCOL']}#{ENV['HOST']}#{Rails.application.class.routes.url_helpers.spa_organization_path(organization)}"
  end

  def organization_community_absolute_url(organization)
    "#{ENV['PROTOCOL']}#{ENV['HOST']}#{Rails.application.class.routes.url_helpers.spa_organization_blog_posts_path(organization_id: organization.id)}"
  end

  def post_absolute_url(post)
    "#{ENV['PROTOCOL']}#{ENV['HOST']}#{Rails.application.class.routes.url_helpers.spa_organization_blog_post_path(
      organization_id: post.organization_id, id: post.id
    )}"
  end
end
