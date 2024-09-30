# frozen_string_literal: true

class BecomePresenter::AddCreator
  def initialize(user, params)
    @params = params
    @user = user
    @channel = @user.owned_channels.first
    @errors = []
  end

  def execute
    unless @channel
      @errors << 'Please create a channel.'
      return false
    end
    @invited_user = if @params[:user_id]
                      # user comes from search tab
                      User.find(@params[:user_id])
                    elsif @params[:email]
                      # user comes from invite by email tab
                      User.find_by(email: @params[:email])
                    else
                      # user comes from got info tab
                      User.find_by(email: @params[:user][:email])
                    end

    if @invited_user.blank?
      @invited_user = User.invite!(user_attrs, @user) do |u|
        u.before_create_generic_callbacks_and_skip_validation
        u.skip_invitation = true
      end
    elsif @invited_user.presenter && @channel.channel_invited_presenterships.exists?(presenter_id: @invited_user.presenter.id)
      @errors << 'User is a creator already.'
      return false
    end

    @invited_user.create_presenter! if @invited_user.presenter.blank?

    if @channel.organization
      member = @channel.organization.organization_memberships_participants.find_or_initialize_by(user: @invited_user,
                                                                                                 status: ::OrganizationMembership::Statuses::ACTIVE)
      if member.new_record?
        member.role = OrganizationMembership::Roles::PRESENTER
        member.save
      end
    end

    invitation = @channel.channel_invited_presenterships.find_or_initialize_by(presenter: @invited_user.presenter)
    if invitation.new_record? && !invitation.save
      @errors << invitation.errors.full_messages
      return false
    end
    true
  end

  def user
    @invited_user
  end

  def errors
    if @invited_user
      @errors << @invited_user.errors.full_messages if @invited_user && @invited_user.errors.present?
      if @invited_user.user_account && !@invited_user.user_account.valid?
        @errors << @invited_user.user_account.errors.full_messages
      end
    end
    @errors.flatten.compact.uniq.join('. ')
  end

  private

  def formatted_attrs
    attributes = user_attrs
    if logo_attrs.present?
      attributes[:image_attributes] = logo_attrs[:logo]
      # attributes[:image_attributes][:image_50_x_50] = logo_attrs[:logo][:original_image]
      # attributes[:image_attributes][:image_253_x_260] = logo_attrs[:logo][:original_image]
      # attributes[:image_attributes][:image_277_x_280] = logo_attrs[:logo][:original_image]
    end
    attributes.to_h
  end

  def user_attrs
    return @params.permit(:email) if @params[:email] # Invite by email

    @params.require(:user).permit(
      :email,
      :first_name,
      :last_name,
      user_account_attributes: [:bio],
      image_attributes: %i[original_image crop_x crop_y crop_w crop_h rotate]
    ).tap do |attrs|
      if attrs[:image_attributes] && attrs[:image_attributes][:original_image]
        # attrs[:image_attributes][:image_50_x_50] = attrs[:image_attributes][:original_image]
        # attrs[:image_attributes][:image_253_x_260] = attrs[:image_attributes][:original_image]
        # attrs[:image_attributes][:image_277_x_280] = attrs[:image_attributes][:original_image]
      end
    end
  end
end
