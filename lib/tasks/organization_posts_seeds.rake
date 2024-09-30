# frozen_string_literal: true

namespace :db do
  namespace :seed do
    desc "Create seed videos for organization_blog, i.e.: 'rake db:seed:organization_blog[62]' will create blog posts and comments for organization #62"
    task :organization_blog, [:organization_id] => :environment do |_task, args|
      p 'Organization id missing.' and next if (args[:organization_id]).blank?

      organization = begin
        Organization.find(args[:organization_id])
      rescue StandardError
        nil
      end
      p 'Organization not found.' and next if organization.blank?

      channels = organization.all_channels.listed.not_archived.limit(5)
      p 'Organization has no channels.' and next unless channels.count.positive?

      channels.find_each do |channel|
        5.times do
          post = FactoryBot.create(:blog_post_published, channel: channel, user: organization.user)
          p "Post id:#{post.id} created."
          10.times do
            comment_author = User.order(Arel.sql('RANDOM()')).limit(1).first
            comment = FactoryBot.create(:blog_comment, commentable: post, user: comment_author)
            p "Post comment id:#{comment.id} created."
            rand(1..5).times do
              comment_author = User.order(Arel.sql('RANDOM()')).limit(1).first
              comment_on_comment = FactoryBot.create(:blog_comment_on_comment, commentable: comment,
                                                                               user: comment_author)
              p "Post comment on comment id:#{comment_on_comment.id} created."
            end
          end
        end
        rand(1..3).times do
          post_hidden = FactoryBot.create(:blog_post_hidden, channel: channel, user: organization.user)
          p "Hidden post id:#{post_hidden.id} created."
        end
        rand(1..3).times do
          post_draft = FactoryBot.create(:blog_post_draft, channel: channel, user: organization.user)
          p "Draft post id:#{post_draft.id} created."
        end
        rand(1..3).times do
          post_archived = FactoryBot.create(:blog_post_archived, channel: channel, user: organization.user)
          p "Archived post id:#{post_archived.id} created."
        end
      rescue StandardError => e
        p e.message
      end
    end
  end
end
