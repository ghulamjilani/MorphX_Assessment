# frozen_string_literal: true

class ChannelProcessPresenterships
  def initialize(user, channel, presenterships)
    @presenterships = presenterships
    @user = user
    @channel = channel
    @errors = []
  end

  def execute
    return true if @presenterships.empty?

    @presenterships.each do |ps|
      if ps[:_destroy]
        @channel.channel_invited_presenterships.find_by(id: ps[:id]).try(:destroy)
        next
      end

      invited_user = case ps[:type]
                     when 'email'
                       User.find_by(email: ps[:email])
                     when 'search'
                       User.find_by(id: ps[:user_id])
                     end

      if invited_user.blank?
        invited_user = User.invite!({ email: ps[:email] }, @user) do |u|
          u.before_create_generic_callbacks_and_skip_validation
          u.skip_confirmation_notification!
          u.skip_invitation = true
        end
      end

      next if invited_user.presenter_id && @channel.channel_invited_presenterships.exists?(presenter_id: invited_user.presenter_id)

      invited_user.create_presenter! if invited_user.presenter.blank?

      presentership = @channel.channel_invited_presenterships.new(presenter_id: invited_user.presenter_id)
      @errors << presentership.errors.full_messages unless presentership.save
    end
    @errors.empty?
  end

  def errors
    @errors.flatten.compact.uniq.join('. ')
  end
end
