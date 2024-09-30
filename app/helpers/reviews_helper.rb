# frozen_string_literal: true

module ReviewsHelper
  def new_star_rating(numeric_rating, classes = 'pull-right')
    result = <<EOL
    <div class="#{classes}" rel="tipsy" title="#{numeric_rating.round(2)}/5">
      <ul class="starRating clearfix">
EOL

    rounded_rating = (numeric_rating * 2).round / 2.0
    1.upto(5) do |i|
      class_name = if i <= numeric_rating
                     'VideoClientIcon-starF'
                   elsif (numeric_rating - i).negative?
                     'VideoClientIcon-star-half-altF'
                   end
      result += if numeric_rating.round >= i
                  %(<li> <i class="#{class_name}" style="text-align: left; "></i> </li>)
                else
                  %(<li> <i class="VideoClientIcon-star-emptyF" style="text-align: left; "></i> </li>)
                end
    end

    result += <<EOL
      </ul>
    </div>
EOL
  end

  # TODO: check usage
  def star_rating(numeric_rating)
    result = <<EOL
    <span class="starRating" title="#{numeric_rating.round(2)}/5">
      <ul class="starRating clearfix">
EOL

    rounded_rating = (numeric_rating * 2).round / 2.0
    1.upto(5) do |i|
      class_name = (rounded_rating == i + 0.5) ? 'VideoClientIcon-star-half-altF' : 'VideoClientIcon-starF'
      result += if numeric_rating >= i
                  %(<li> <i class="#{class_name}" style="text-align: left; "></i> </li>)
                else
                  %(<li> <i class="VideoClientIcon-star-emptyF" style="text-align: left; "></i> </li>)
                end
    end

    result += <<EOL
      </ul>
    </span>
EOL
  end

  def ver2_star_rating(numeric_rating, additional_ul_class = '')
    result = <<EOL
      <ul class="starRating clearfix inline-block #{additional_ul_class} rating-#{numeric_rating.round(2)}/5">
EOL

    rounded_rating = (numeric_rating * 2).round / 2.0
    1.upto(5) do |i|
      class_name = (rounded_rating == i + 0.5) ? 'VideoClientIcon-star-half-altF' : 'VideoClientIcon-starF'
      result += if numeric_rating >= i
                  %(<li> <i class="#{class_name}" style="text-align: left; "></i> </li>)
                else
                  %(<li> <i class="VideoClientIcon-star-emptyF" style="text-align: left; "></i> </li>)
                end
    end

    result += <<EOL
      </ul>
EOL
  end

  def session_rating(numeric_rating)
    result = <<EOL
      <ul class="starRating clearfix rating-#{numeric_rating.round(2)}">
EOL

    rounded_rating = (numeric_rating * 2).round / 2.0
    1.upto(5) do |i|
      class_name = (rounded_rating == i + 0.5) ? 'VideoClientIcon-star-half-altF' : 'VideoClientIcon-starF'
      result += if numeric_rating >= i
                  %(<li> <i class="#{class_name}"></i> </li>)
                else
                  %(<li> <i class="VideoClientIcon-star-emptyF"></i> </li>)
                end
    end

    result += <<EOL
    </ul>
EOL
  end

  def display_mark_all_notifications_as_read?
    !Rails.env.production? && !Rails.env.qa?
  end

  def display_clear_all_notifications?
    !Rails.env.production? && !Rails.env.qa?
  end

  def display_notification_tabs?
    !Rails.env.production? && !Rails.env.qa?
  end

  def display_messages_management_tools?
    !Rails.env.production? && !Rails.env.qa?
  end

  def comment_input_html_params
    {
      placeholder: '',
      rows: '2',
      cols: '46',
      style: 'width: auto',
      class: 'form-control'
    }.tap do |h|
      unless can?(:create_or_update_review_comment, @session)
        h[:disabled] = 'disabled'
      end
    end
  end

  def numeric_rating_for(rateable_obj, dimension = Session::RateKeys::QUALITY_OF_CONTENT)
    cached_average = rateable_obj.average dimension
    avg = cached_average ? cached_average.avg : 0
    avg.round(2)
  end

  def rates_quantity(rateable_obj)
    Rate.where(rateable: rateable_obj).uniq(:rater_id).pluck(:rater_id).length
  end

  def raters_quantity(rateable_obj, dimension = Session::RateKeys::QUALITY_OF_CONTENT)
    rateable_obj.raters(dimension).count
  end

  def referred_five_friends_a_tag(&block)
    result = capture_haml(&block)

    if referred_five_friends_completed?
      raw "<a href='#'>#{result}</a>"
    else
      raw "<a href='#' data-target='#ReferFiveFriendsModal' data-toggle='modal'>#{result}</a>"
    end
  end

  # taken from https://github.com/muratguzel/letsrate/blob/master/lib/letsrate/helpers.rb#L2
  def user_rating_for(given_stars)
    content_tag :div, '', class: 'star', style: 'width: auto !important', 'data-rating' => given_stars,
                          'data-readonly' => true,
                          'data-star-count' => Session::RATING_MAX_START
  end

  def rating_for_google(rateable_obj)
    dimension = Session::RateKeys::QUALITY_OF_CONTENT
    cached_average = rateable_obj.average dimension
    avg = cached_average ? cached_average.avg : 0
    # https://support.google.com/webmasters/answer/146645?hl=en&ref_topic=4599102 - docs
    # http://www.google.com/webmasters/tools/richsnippets - a tool to check functional of this code
    unless avg.zero?
      %(
          <div itemscope itemtype="http://data-vocabulary.org/Review">
            <span itemprop="itemreviewed">#{rateable_obj.always_present_title}</span>
            Reviewed by <span itemprop="reviewer">#{pluralize(rateable_obj.reviews_with_comment.length, 'person',
                                                              'people')}</span> on
            <time itemprop="dtreviewed" datetime="#{rateable_obj.updated_at.to_date.to_fs(:db)}">#{rateable_obj.updated_at.strftime('%b%e')}</time>.
            Rating: <span itemprop="rating">#{number_with_precision(avg, precision: 1)}</span>
          </div>
      ).html_safe
    end
  end

  # taken from https://github.com/muratguzel/letsrate/blob/master/lib/letsrate/helpers.rb#L2
  def rating_with_tooltip_for(rateable_obj, dimension, options = {})
    # NOTE: this option is needed for more unbiased voting
    #      user can't see average rating at the time of his vote
    if options[:ignore_average_rating]
      rate = Rate.where(rater: current_user, dimension: dimension, rateable: rateable_obj).first
      rating = if rate.present?
                 rate.stars
               else
                 0
               end
    else
      cached_average = rateable_obj.average dimension
      rating = cached_average ? cached_average.avg : 0
    end

    star         = options[:star]         || Session::RATING_MAX_START
    enable_half  = options[:enable_half]  || false
    half_show    = options[:half_show]    || true
    star_path    = '' # options[:star_path]    || '/assets'
    star_on      = options[:star_on]      || asset_path('/star-on.png')
    star_off     = options[:star_off]     || asset_path('/star-off.png')
    star_half    = options[:star_half]    || asset_path('/star-half.png')
    cancel       = options[:cancel]       || false
    cancel_place = options[:cancel_place] || 'left'
    cancel_hint  = options[:cancel_hint]  || 'Cancel current rating!'
    cancel_on    = options[:cancel_on]    || asset_path('/cancel-on.png')
    cancel_off   = options[:cancel_off]   || asset_path('/cancel-off.png')
    noRatedMsg   = options[:noRatedMsg]   || 'I\'am readOnly and I haven\'t rated yet!'
    # round        = options[:round]        || { down: .26, full: .6, up: .76 }
    space        = options[:space]        || false
    single       = options[:single]       || false
    target       = options[:target]       || ''
    targetText   = options[:targetText]   || ''
    targetType   = options[:targetType]   || 'hint'
    targetFormat = options[:targetFormat] || '{score}'
    targetScore  = options[:targetScore]  || ''
    readOnly = options[:readonly] || false

    disable_after_rate = options[:disable_after_rate] && true
    disable_after_rate = true if disable_after_rate.nil?

    readonly = if disable_after_rate
                 !(current_user && rateable_obj.can_rate?(current_user, dimension))
               else
                 !current_user || false
               end

    if options[:imdb_avg] && readonly
      content_tag :div, '',
                  style: "background-image:url('#{asset_path('/mid-star.png')}');width:61px;height:57px;margin-top:10px;" do
        content_tag :p, rating, style: 'position:relative;font-size:.8rem;text-align:center;line-height:60px;'
      end
    else
      content_tag :div, '', 'data-dimension' => dimension, class: 'star', 'data-rating' => rating,
                            'data-id' => rateable_obj.id, 'data-classname' => rateable_obj.class.name,
                            'data-disable-after-rate' => disable_after_rate,
                            'data-readonly' => readOnly,
                            'data-enable-half' => enable_half,
                            'data-half-show' => half_show,
                            'data-star-count' => star,
                            'data-star-path' => star_path,
                            'data-star-on' => star_on,
                            'data-star-off' => star_off,
                            'data-star-half' => star_half,
                            'data-cancel' => cancel,
                            'data-cancel-place' => cancel_place,
                            'data-cancel-hint' => cancel_hint,
                            'data-cancel-on' => cancel_on,
                            'data-cancel-off' => cancel_off,
                            'data-no-rated-message' => noRatedMsg,
                            # "data-round" => round,
                            'data-space' => space,
                            'data-single' => single,
                            'data-target' => target,
                            'data-target-text' => targetText,
                            'data-target-type' => targetType,
                            'data-target-format' => targetFormat,
                            'data-target-score' => targetScore
    end
  end
end
