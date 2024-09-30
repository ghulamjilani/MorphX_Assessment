# frozen_string_literal: true

module ThankYousHelper
  def under_price_comment
    # case params[:type]
    # when ObtainTypes::PAID_VOD
    #  pluralize(@session.session_participations.count + @session.session_participations.count, 'participant')
    # else
    #  raise ArgumentError, "can not interpret #{params[:type]}"
    # end

    # TODO: - check what kind of purchase was that?
    if @abstract_session.is_a?(Session)
      pluralize(@abstract_session.session_participations.count + @abstract_session.livestreamers.count, 'participant')
    else
      raise ArgumentError, "can not interpret #{@abstract_session.class}"
    end
  end

  def delivery_method_title
    case params[:type]
    when ObtainTypes::FREE_IMMERSIVE, ObtainTypes::PAID_IMMERSIVE
      'Immersive'
    when ObtainTypes::FREE_LIVESTREAM, ObtainTypes::PAID_LIVESTREAM
      'Livestream'
    when ObtainTypes::FREE_VOD, ObtainTypes::PAID_VOD
      'Video On-Demand'
    else
      raise ArgumentError, "can not interpret #{params[:type]}"
    end
  end

  def delivery_method_icon_suffix
    # NOTE: see app/assets/images/search/ icons
    case params[:type]
    when ObtainTypes::FREE_IMMERSIVE, ObtainTypes::PAID_IMMERSIVE
      'Immersive.png'
    when ObtainTypes::FREE_LIVESTREAM, ObtainTypes::PAID_LIVESTREAM
      'Livestream.png'
    when ObtainTypes::FREE_VOD, ObtainTypes::PAID_VOD
      'On-Demand.png'
    else
      raise ArgumentError, "can not interpret #{params[:type]}"
    end
  end
end
