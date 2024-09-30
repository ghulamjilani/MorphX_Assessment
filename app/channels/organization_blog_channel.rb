# frozen_string_literal: true

class OrganizationBlogChannel < ApplicationCable::Channel
  EVENTS = {
    post_status_updated: 'Post status updated. Data: { id: id, status: status }',
    post_slug_updated: 'Post slug updated. Data: { id: id, slug: slug, relative_path: relative_path }',
    post_title_updated: 'Post title updated. Data: { id: id, title: title }',
    post_body_updated: 'Post body updated. Data: { id: id, body: body }',
    post_body_preview_updated: 'Post body preview updated. Data: { id: id, body_preview: body_preview }',
    post_link_preview_updated: 'Post featured_link_preview_id changed. Data: { id: id, link_preview_id: featured_link_preview_id }',
    post_published: 'Post status changed to published. Data: post.as_json',
    post_likes_count_updated: 'Post likes count changed. Data: {id: @post.id, likes_count: @post.likes_count}'
  }.freeze

  def subscribed
    organization = Organization.find_by(id: params[:data])

    stream_from 'organization_blog_channel'

    if organization.present?
      stream_for organization
    end
  end

  def unsubscribed
  end
end
