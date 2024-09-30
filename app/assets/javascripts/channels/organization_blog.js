const organizationBlogChannelEvents = {
  postStatusUpdated: 'post_status_updated',
  postSlugUpdated: 'post_slug_updated',
  postTitleUpdated: 'post_title_updated',
  postBodyUpdated: 'post_body_updated',
  postBodyPreviewUpdated: 'post_body_preview_updated',
  postLinkPreviewUpdated: 'post_link_preview_updated',
  postPublished: 'post_published',
  postLikesCountUpdated: 'post_likes_count_updated'
}

function initOrganizationBlogChannel(id) {
  return initChannel('OrganizationBlogChannel', {data: id});
}
