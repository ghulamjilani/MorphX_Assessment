# frozen_string_literal: true

module SearchModelsHelper
  def pattern_search_api(model)
    {
      'response' => a_hash_including(
        'documents' => a_collection_including(
          a_hash_including(
            'document' => a_hash_including(
              'searchable_id' => model.id,
              'searchable_type' => model.class.name
            ),
            'searchable_model' => a_hash_including(
              model.class.to_s.downcase => a_hash_including(
                'id' => model.id
              )
            )
          )
        )
      )
    }
  end

  def pattern_search_api_user(model)
    {
      'response' => a_hash_including(
        'users' => a_collection_including(
          a_hash_including(
            'user' => a_hash_including(
              'id' => model.id,
              'public_display_name' => model.public_display_name
            )
          )
        )
      )
    }
  end

  def pattern_search_api_channel(model)
    {
      'response' => a_hash_including(
        'channels' => a_collection_including(
          a_hash_including(
            'channel' => a_hash_including(
              'id' => model.id
            )
          )
        )
      )
    }
  end

  def pattern_search_api_session(model)
    {
      'response' => a_hash_including(
        'sessions' => a_collection_including(
          a_hash_including(
            'session' => a_hash_including(
              'id' => model.id
            )
          )
        )
      )
    }
  end

  def pattern_search_api_video(model)
    {
      'response' => a_hash_including(
        'videos' => a_collection_including(
          a_hash_including(
            'video' => a_hash_including(
              'id' => model.id
            )
          )
        )
      )
    }
  end

  def pattern_search_api_recording(model)
    {
      'response' => a_hash_including(
        'recordings' => a_collection_including(
          a_hash_including(
            'recording' => a_hash_including(
              'id' => model.id
            )
          )
        )
      )
    }
  end

  def pattern_organization_membership(model)
    {
      'response' => a_hash_including(
        'organization_memberships' => a_collection_including(
          a_hash_including(
            'organization_membership' => a_hash_including(
              'id' => model.id
            )
          )
        )
      )
    }
  end
end
