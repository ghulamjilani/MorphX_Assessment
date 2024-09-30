# frozen_string_literal: true

namespace :pg_search do
  namespace :multisearch do
    task reindex: :environment do
      p 'Reindexing users...'
      User.multisearch_reindex
      p 'Done!'

      p 'Reindexing channels...'
      Channel.multisearch_reindex
      p 'Done!'

      p 'Reindexing sessions...'
      Session.multisearch_reindex
      p 'Done!'

      p 'Reindexing videos...'
      Video.multisearch_reindex
      p 'Done!'

      p 'Reindexing recordings...'
      Recording.multisearch_reindex
      p 'Done!'
    end

    task reindex_user: :environment do
      p 'Reindexing users...'
      User.multisearch_reindex
      p 'Done!'
    end

    task reindex_channel: :environment do
      p 'Reindexing channels...'
      Channel.multisearch_reindex
      p 'Done!'
    end

    task reindex_session: :environment do
      p 'Reindexing sessions...'
      Session.multisearch_reindex
      p 'Done!'
    end

    task reindex_video: :environment do
      p 'Reindexing videos...'
      Video.multisearch_reindex
      p 'Done!'
    end

    task reindex_recording: :environment do
      p 'Reindexing recordings...'
      Recording.multisearch_reindex
      p 'Done!'
    end
  end
end
