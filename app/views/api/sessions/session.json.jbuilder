# frozen_string_literal: true

envelope json, (@status || 200), (@session.pretty_errors if @session.errors.present?) do
  json.session do
    json.id                             @session.id
    json.adult                          @session.adult
    json.age_restrictions               @session.age_restrictions
    json.custom_description_field_label @session.custom_description_field_label
    json.description                    @session.description
    json.duration                       @session.duration
    json.free_trial_for_first_time_participants @session.free_trial_for_first_time_participants
    # json.immersive                      @session.immersive
    json.immersive_free                 @session.immersive_free
    json.immersive_access_cost          @session.immersive_access_cost
    json.immersive_free_trial           @session.immersive_free_trial
    json.immersive_free_slots           @session.immersive_free_slots
    json.immersive_type                 @session.immersive_type
    json.level                          @session.level
    # json.livestream                     @session.livestream
    json.livestream_free                @session.livestream_free
    json.livestream_access_cost         @session.livestream_access_cost
    json.livestream_free_trial          @session.livestream_free_trial
    json.livestream_free_slots          @session.livestream_free_slots
    json.max_number_of_immersive_participants @session.max_number_of_immersive_participants
    json.min_number_of_immersive_and_livestream_participants @session.min_number_of_immersive_and_livestream_participants
    json.pre_time                       @session.pre_time
    json.presenter_id                   @session.presenter_id
    json.private                        @session.private
    json.publish_after_requested_free_session_is_satisfied_by_admin @session.publish_after_requested_free_session_is_satisfied_by_admin
    # json.record                         @session.record
    json.recorded_free                  @session.recorded_free
    json.recorded_access_cost           @session.recorded_access_cost
    json.requested_free_session_reason  @session.requested_free_session_reason
    json.custom_description_field_value @session.custom_description_field_value
    json.start_at                       @session.start_at.to_fs(:rfc3339)
    json.start_now                      @session.start_now
    json.autostart                      @session.autostart
    json.service_type                   @session.service_type
    json.title                          @session.title
    json.twitter_feed_title             @session.twitter_feed_title
    json.room_id                        @session.room.try(:id)
    json.watchers_count                 @session.room&.watchers_count || 0
  end
end
