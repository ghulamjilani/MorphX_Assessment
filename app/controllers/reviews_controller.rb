# frozen_string_literal: true

class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_dimension, only: [:rate]

  def rate
    score = params[:score].to_f

    begin
      @model = params[:klass].constantize.find(params[:model_id])

      @model = @model.session if @model.is_a?(Video)

      authorize!(:read, @model)

      raise ArgumentError, "fraud attempt - #{score}" if score > Session::RATING_MAX_START

      if @model.organizer == current_user && ::Session::RateKeys::PRESENTER.exclude?(params[:dimension])
        raise ArgumentError,
              'fraud attempt'
      end
      if @model.is_a?(Session) && @model.room_members.banned.exists?(abstract_user: current_user)
        raise ArgumentError,
              'You have been banned from this session'
      end

      @model.rate_as_new_or_update_existing(score, current_user, params[:dimension])
      @model.touch
      @model.channel.touch
      rating = begin
        @model.average(Session::RateKeys::QUALITY_OF_CONTENT).avg.round(2)
      rescue StandardError
        0.0
      end

      if @model.respond_to?(:room)
        PublicLivestreamRoomsChannel.broadcast_to(@model.room, { event: 'rating_updated', data: { rating: rating } })
        PrivateLivestreamRoomsChannel.broadcast_to(@model.room, { event: 'rating_updated', data: { rating: rating } })
      end

      @rated_mandatory_criteria = Rate.where(rater: current_user, dimension: Session::RateKeys::MANDATORY,
                                             rateable: @model).count == Session::RateKeys::MANDATORY.size
      if @rated_mandatory_criteria
        TodoAchievement.find_or_create_by(user: current_user, type: TodoAchievement::Types::REVIEW_A_SESSION)
      end
      type = params[:klass].casecmp('session').zero? ? :session : :video
      dropdown_html = render_to_string('shared/player/_rating_dropdown', format: :html, layout: false,
                                                                                   locals: { model: @model, content_type: type }).html_safe
      respond_to do |format|
        format.js
        format.json { render json: { dropdown: dropdown_html } }
      end
    rescue StandardError => e
      Rails.logger.debug e.message
      respond_to do |format|
        format.js { head :unauthorized }
        format.json { render(json: { error: e.message }, status: 401) }
      end
    end
  end

  def comment
    @model = params[:klass].constantize.find(params[:model_id])
    @model = @model.session if @model.is_a?(Video)

    @comment = @model.reviews.find_by(user: current_user).tap do |comment|
      comment.attributes = review_params if comment.present?
    end || @model.reviews.new(review_params).tap { |c| c.user = current_user }

    if @comment.save
      TodoAchievement.find_or_create_by(user: current_user, type: TodoAchievement::Types::REVIEW_A_SESSION)

      type = params[:klass].casecmp('session').zero? ? :session : :video
      dropdown_html = render_to_string('shared/player/_rating_dropdown', format: :html, layout: false,
                                                                                   locals: { model: @model, content_type: type }).html_safe

      unless current_user == @model.organizer
        ::Immerss::Mailboxer::Notification.save_with_receipt(
          user: @model.organizer,
          subject: "Left a new review for the <a href='#{@model.absolute_path}'>#{@model.title}</a> session",
          sender: current_user,
          body: @comment.overall_experience_comment
        )
      end

      flash.now[:success] = I18n.t('controllers.reviews.session_has_been_reviewed') unless params[:skip_flash]
      respond_to do |format|
        format.js
        format.json { render json: { dropdown: dropdown_html } }
      end
    else
      flash.now[:error] = @comment.errors.full_messages.first unless params[:skip_flash]
      respond_to do |format|
        format.js
        format.json { render json: { message: @comment.errors.full_messages.first }, status: 422 }
      end
    end
  end

  private

  def validate_dimension
    unless Session::RateKeys::ALL.include?(params[:dimension])
      raise ArgumentError, "dimension - #{params[:dimension]}, allowed only these: #{Session::RateKeys::ALL.inspect}"
    end
  end

  def review_params
    params.require(:comment).permit(:title, :overall_experience_comment, :technical_experience_comment)
  end
end
