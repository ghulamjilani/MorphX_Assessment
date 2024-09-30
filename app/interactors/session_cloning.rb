# frozen_string_literal: true

class SessionCloning
  def initialize(original_session)
    @original_session = original_session

    @merge_attrs = {}
  end

  # NOTE: we don't clone co-presenter invites here on purpose
  def with_invites!
    @merge_attrs[:session_invited_immersive_participantships_attributes] =
      @original_session.session_invited_immersive_participantships.as_json(only: [:participant_id])
    @merge_attrs[:session_invited_livestream_participantships_attributes] =
      @original_session.session_invited_livestream_participantships.as_json(only: [:participant_id])
  end

  def with_dropbox_materials!
    @merge_attrs[:dropbox_materials_attributes] =
      @original_session.dropbox_materials.as_json(except: %i[id created_at updated_at abstract_session_id
                                                             abstract_session_type])
  end

  # @return[Session] unpersisted with all necessary nested associations
  def clone_and_return_session
    _attrs = @original_session.attributes.symbolize_keys.slice(
      :adult,
      :age_restrictions,
      :description,
      :duration,
      :immersive_free,
      :immersive_purchase_price,
      :immersive_type,
      :level,
      :custom_description_field_label,
      :livestream_free,
      :livestream_purchase_price,
      :max_number_of_immersive_participants,
      :min_number_of_immersive_and_livestream_participants,
      :private,
      :recorded_free,
      :recorded_purchase_price,
      :custom_description_field_value,
      :title,
      :allow_chat,
      :pre_time,
      :start_now,
      :autostart,
      :service_type,
      :device_type,
      :presenter_id,
      :recording_layout,
      :ffmpegservice_account_id
    )
    if @merge_attrs.present?
      _attrs.merge! @merge_attrs
    end
    result = @original_session.channel.sessions.build(_attrs)
    result.list_ids = @original_session.list_ids
    result
  end
end
