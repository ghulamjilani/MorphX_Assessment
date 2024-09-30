# frozen_string_literal: true

module ModelConcerns::Session::HasInvitedUsers
  module States
    IMMERSIVE_AND_LIVESTREAM = 'immersive-and-livestream'
    IMMERSIVE                = 'immersive'
    LIVESTREAM               = 'livestream'
    CO_PRESENTER             = 'co-presenter'

    ALL = [
      IMMERSIVE_AND_LIVESTREAM,
      IMMERSIVE,
      LIVESTREAM,
      CO_PRESENTER
    ].freeze
  end

  # @return [Array]
  # example result - => [{state:'immersive', email:"u2@gmail.com", display_name:"u2"}, {state:'livecast', email:"u1@gmail.com", display_name:"u1"}]
  def invited_users_as_json
    x1 = session_invited_immersive_participantships.collect do |o|
           [o.user_id,
            o.status]
         end.collect do |user_id, status|
      { user_id => { state: ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE,
                     status: status } }
    end
    x2 = session_invited_livestream_participantships.where(session: self).collect do |o|
           [o.user_id,
            o.status]
         end.collect do |user_id, status|
      { user_id => { state: ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM,
                     status: status } }
    end

    x3 = SessionInvitedImmersiveCoPresentership.where(session: self).collect do |o|
           [o.user_id,
            o.status]
         end.collect do |user_id, status|
      { user_id => { state: ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER,
                     status: status } }
    end

    result = (x1 | x2 | x3).flat_map(&:entries).group_by(&:first).map do |key, value|
      methods = value.map(&:last)
      result = methods.reduce({}) do |h, pairs|
        pairs.each do |k, v|
          # NOTE: if user is invited to both delivery methods, we re-assign its state to Concerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM
          case k
          when :state
            if h[k].present?
              if (h[k] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE && v == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM) ||
                 (h[k] == ModelConcerns::Session::HasInvitedUsers::States::LIVESTREAM && v == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE)
                h[k] = ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM
              elsif h[k] == ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE_AND_LIVESTREAM
                # already set, do not override it
              else
                h[k] = v
              end
            else
              h[k] = v
            end
          when :status
            (h[k] ||= []) << v
          else
            h[k] = v
          end
        end
        h
      end
      # result.inspect
      # {state:'immersive-and-livecast', status:["accepted", "pending"]}
      case result[:status].length
      when 1
        status = result[:status].first
      when 2
        # NOTE: x1 & x2 could be in different statuses for same participant.
        # Use cases:
        # invited to both accepted one
        # invited to one, rejected it, invited again to the other method later
        statuses = result[:status]

        # NOTE: keep this logic in sync with #invited_participant_status - it fixes #1818
        status = if statuses.include?(ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED)
                   ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED
                 elsif statuses.include?(ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING)
                   ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
                 else
                   ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED
                 end
      else
        raise "can not interptet #{result.inspect}"
      end
      result[:status] = status

      Hash[key, result]
    end

    user_ids = result.collect(&:keys).flatten
    additional_data = User.where(id: user_ids).pluck(:id, :email, :display_name)

    result.each_with_index.map do |hash, _i|
      user_id                      = hash.keys.first
      hash[user_id][:email]        = additional_data.find { |arr| arr.include?(user_id) }[1]

      _cache_key                   = "avatar_url/#{hash[user_id][:email]}/#{Date.today.strftime('%U').to_i}" # weekly expiration
      hash[user_id][:avatar_url]   = Rails.cache.fetch(_cache_key) do
        User.find_by(email: hash[user_id][:email]).avatar_url
      end

      hash[user_id][:display_name] = additional_data.find { |arr| arr.include?(user_id) }[2]
      hash
    end
    # result.inspect
    #=>[{98=>{state:'immersive-and-livecast', email:"user1@example.com", display_name:"John last-name-1"}}, {99=>{state:'immersive', email:"user2@example.com", display_name:"xxx"}}]

    result.collect(&:values).flatten
  end
end
