# frozen_string_literal: true

class WizardV2::ChannelController < WizardV2::ApplicationController
  before_action :authenticate_user!
  before_action :check_business

  def show
    @channel = current_user.channels.first || Channel.new
    current_user.presenter.update({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP3 })
  end

  def update
    @interactor = BecomePresenter::SaveChannelInfo.new(current_user, channel_attributes)
    if @interactor.execute
      current_user.presenter.update!({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::DONE })
      redirect_path = if Rails.application.credentials.global.dig(:wizard, :summary)
                        wizard_v2_summary_path
                      else
                        dashboard_path
                      end
      respond_to do |format|
        format.html do
          flash[:success] = 'Channel Saved'
          redirect_to redirect_path
        end
        format.json { render json: { redirect_path: redirect_path }, status: 200 }
      end
    else
      errors = @interactor.errors
      respond_to do |format|
        format.html do
          @channel = @interactor.channel
          flash[:error] = errors
          render :show
        end
        format.json { render json: errors, status: 422 }
      end
    end
  end

  private

  def channel_attributes
    if params[:channel].present?
      params.require(:channel).permit(
        :id,
        :title,
        :description,
        :category_id,
        :channel_type_id,
        :tag_list,
        :tagline,
        :organization_id,
        :show_comments,
        :show_reviews,
        :im_conversation_enabled,
        :show_documents,
        cover_attributes: %i[id crop_x crop_y crop_w crop_h rotate is_main image]
      ).tap do |attributes|
        attributes.delete('id') if attributes['id'] == ''
        attributes.delete(:cover_attributes) unless attributes[:cover_attributes] && attributes[:cover_attributes][:image].present?
      end
    end
  end

  def check_business
    unless current_user.organization
      respond_to do |format|
        format.html do
          redirect_to wizard_v2_business_path
        end
        format.json { render json: { message: 'No organization found' }, status: 422 }
      end
    end
  end
end
