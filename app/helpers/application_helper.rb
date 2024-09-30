# frozen_string_literal: true

module ApplicationHelper
  def show_drift?
    drift_conf = Rails.application.credentials.global[:drift]
    return false unless drift_conf&.dig(:show)

    if drift_conf[:only_landing]
      (controller_name == 'home' && %w[landing].include?(action_name))
    else
      %w[channels dashboards posts
         comments].include?(controller_name) || (controller_name == 'home' && %w[landing discover
                                                                                 index].include?(action_name)) || (controller_name == 'not_found_or_title_parameterized' && @channel && !@session && !@recording)
    end
  end

  def display_currency_chooser?
    !Rails.env.production?
  end

  # Fixes #1926 #1928
  # depending on user's role we either display
  # live session(if there is one),
  # or "create new session"(organizer)
  # or "request session"(visitor)
  def session_link_a_tag(session, css_class, &block)
    result = capture_haml(&block)
    raise ArgumentError if result.blank?

    classes = [css_class]

    if session.persisted?
      content_tag(:a, href: session.relative_path, class: classes) { result }
    elsif @channel.organizer == current_user
      # TODO: Check places like this when channel members roles will be added
      # for now only organizer can create and assign sessions to other channel members
      content_tag(:a, href: new_channel_session_path(session.channel.slug), class: classes) { result }
    else
      classes += ['ensure-link-style']
      content_tag(:a, class: classes, onclick: 'openRequestNewSessionForm(event, this, this.offsetWidth)') { result }
    end
  end

  def session_relative_path_with_video_anchor(session, video_id)
    "#{session.relative_path}#{video_anchor(session, video_id) if video_id}"
  end

  def sign_up_email_input_html_value
    { placeholder: 'Email', class: 'form-control', autocomplete: :off, minlength: 6, maxlength: 128 }.tap do |hash|
      hash[:disabled] = 'disabled' if controller_name == 'invitations' && action_name == 'edit'
    end
  end

  def popover_attributes(container = nil)
    return {} if container.nil?

    { data: { container: container, trigger: :manual, toggle: :popover, placement: :right, content: '' } }
  end

  def devise_invitation_token_in_signup_modal
    if controller_name == 'invitations' && action_name == 'edit'
      # NOTE: if you're brave enough to change the following line then you need to re-test invitations and completing accounts with social methods
      User.find(resource.id).read_attribute(:invitation_token)
    else
      nil
    end
  end

  # vanilla body_class helper method
  # that is aware of high_voltage
  # otherwise you never know what page is that exactly
  def enhanced_body_class
    if controller_name == 'pages' && action_name == 'show'
      return "#{body_class} #{params[:id].parameterize}"
    end

    body_class
  end

  def display_todo_modal?
    return false unless user_signed_in?
    return false if Rails.env.qa? || Rails.env.production?

    !TodoAchievement.all_checked_for?(current_user)
  end

  # @see https://github.com/thoughtbot/flutie/blob/master/lib/flutie/page_title_helper.rb to get an idea
  def page_header_title
    content_for(:page_title)
  end

  def dropdown_with_icons(&block)
    result = capture_haml(&block)
    return '' if result.blank?

    doc = Nokogiri::HTML result
    nodes = doc.css('li').remove
    nodes.sort_by { |node| node.text.strip }.each { |node| doc.first_element_child.first_element_child << node }
    html = doc.first_element_child.first_element_child.children.to_html.html_safe

    raw <<EOL
      <div class="dropdown dropdown-list pull-right NoMinWidth clearfix">
        <a class="btn-grey-small More-dropdown dropdown-toggle NoMinWidth" role="button" rel="tipsy" tittle="Edit" href="#" data-toggle="dropdown">
          <i class="VideoClientIcon-dots-horizontal-triple"></i>
        </a>
        <ul class="dropdown-menu full-width dropdown-menu-withIcons">
          #{html}
        </ul>
      </div>
      <div class='clearfix'></div>

EOL
  end

  def set_your_password_page?
    controller_name == 'invitations'
  end

  def birthdate_tooltip_hint
    title = I18n.t('signup.birthdate_tooltip', service_name: Rails.application.credentials.global[:service_name])
    %(<a data-html=true data-toggle="tooltip" data-placement="bottom" title="#{title}">Why do I need to provide my birthday?</a>).html_safe
  end

  def lets_get_started_button
    # TODO[low priority] check if user is already a confirmed presenter
    _link = work_with_us_link

    # TODO: check if we still need this
    # preventing circular link
    if work_with_us_link == business_home_path
      _link = wizard_v2_path
    end

    if current_user_has_unconfirmed_email?
      link_to('START CREATING', '#', class: 'margin-bottom-20 BAP_btn scrollrInit', onclick: "alert('You have to confirm your email address before continuing.')",
                                     'data-21' => 'position:static;background-color:rgba(255, 255, 255, 0.5);',
                                     'data-72-top' => ';position:fixed;top:72px;background-color:rgba(255, 255, 255, 0.5);',
                                     'data-21-top' => 'position:fixed;top:23px;z-index: 9999; border-color: rgb(16, 176, 230);background-color:rgba(16, 176, 230, 1);')
    else
      link_to('START CREATING', _link, class: 'margin-bottom-20 BAP_btn scrollrInit',
                                       'data-21' => 'position:static;background-color:rgba(255, 255, 255, 0.5);',
                                       'data-10-top' => 'position:fixed;top:-30px; background-color:rgba(255, 255, 255, 0.5);',
                                       'data--21-top' => 'position:fixed;top:23px;z-index: 9999; border-color: rgb(16, 176, 230);background-color:rgba(16, 176, 230, 1);')
    end
  end

  def lets_get_started_button_link
    # TODO[low priority] check if user is already a confirmed presenter
    _link = work_with_us_link

    # TODO: check if we still need this
    # preventing circular link
    if work_with_us_link == business_home_path
      _link = wizard_v2_path
    end
    { link: _link, onclick: '' }
  end

  def display_top_navigation?
    user_signed_in?
  end

  def country_state_wrapper_style(user_account)
    user_account.us_country? ? '' : 'display: none'
  end

  def recorded_access_cost_wrapper_style
    display_when_session = params[:session].present? && params[:session][:record].to_i == 1
    display_when_session ? '' : 'display: none'
  end

  def new_notifications_count
    return 0 unless user_signed_in?

    Rails.cache.fetch(current_user.new_notifications_count_cache_key) do
      current_user.reminder_notifications.unread.count
    end.to_i
  end

  def notifications_tab_class
    new_notifications_count.positive? ? 'blink_me' : ''
  end

  def messages_tab_class
    current_user.unread_messages_count.positive? ? 'blink_me' : ''
  end

  def unread_messages_count
    count = current_user.unread_messages_count
    count.positive? ? count : ''
  end

  def link_to_has_many(association, name, f, append_tag = :hr, link_class = nil)
    # reason is because we build model hierarchy for saving and if there is some issues in for example "session_invited_participanthips"
    # those records wouldn't be presenter as #invited_participants association(and therefor visible in the form)
    #
    # persisted object may throw "ActiveRecord::RecordInvalid  # Validation failed: Email has already been taken" on failed validated
    # when doing f.object.send(association) << klass.new(user: User.new(email: email))
    # that seems like an acceptable workaround because flash message with clear explanation of failed validation is displayed.
    if !f.object.persisted? && association.to_s.include?('invited_')
      # assoc_name could be like "session_invited_participanthips"
      assoc_name = "#{f.object.class.to_s.downcase}_#{association.to_s.gsub('co_presenters', 'co_presenterships').gsub(
        'participants', 'participantships'
      )}"

      not_persisted_invalid_emails = f.object.send(assoc_name).collect(&:email) - f.object.send(association).collect(&:email)
      klass = association.to_s.gsub('invited_', '').gsub('co_', '')[0..-2].capitalize.constantize
      not_persisted_invalid_emails.each do |email|
        # #invited_participants << Participant.new for example
        f.object.send(association) << klass.new(user: User.new(email: email))
      end
    end

    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render("#{association.to_s.singularize}_fields", f: builder, abstract_session: f.object) + content_tag(append_tag)
    end
    link_to(raw(name), '#', class: "#{link_class} add_#{association}",
                            data: { id: id, association.to_sym => fields.delete("\n") })
  end

  def rails_to_bootstrap_message(name)
    case name.to_s
    when 'notice'
      'success'
    when 'alert'
      'danger'
    else
      'info'
    end
  end

  def dashboard_status_column_content(abstract_session, force_join_link = false)
    return 'Cancelled' if abstract_session.cancelled?

    return 'Completed' if Time.zone.now > abstract_session.end_at
    return 'Completed' if abstract_session.stopped?

    if user_signed_in?
      return pending_invitation_link(abstract_session).html_safe if pending_invitation_link(abstract_session).present? and !force_join_link
      return 'Declined' if rejected_invitation?(abstract_session)
    end

    raw join_room(abstract_session, 'session-head-btn mainButton btn',
                  initialization_type: JoinInitializationTypes::DASHBOARD).html_link
  end

  def pending_invitation_link(abstract_session)
    Rails.cache.fetch("#{__method__}/#{abstract_session.cache_key}/#{current_user.id}") do
      if abstract_session.is_a?(Session)
        if can?(:accept_or_reject_invitation, abstract_session)
          <<~EOL
                        #{link_to '<i class="icon-ok"></i>'.html_safe,
                                  accept_invitation_session_path(abstract_session.id),
                                  alt: 'Accept invitation',
                                  title: 'Accept invitation',
                                  class: 'btn btn-success',
                                  data: { disable_with: 'Please wait…' },
                                  method: :post }
            #{'            '}
                                  #{link_to '<i class="icon-remove"></i>'.html_safe,
                                            reject_invitation_session_path(abstract_session.id),
                                            alt: 'Decline invitation',
                                            title: 'Decline invitation',
                                            class: 'btn btn-warning',
                                            method: :post,
                                            data: { disable_with: 'Please wait…' } }
          EOL
        end.to_s.html_safe
      else
        raise abstract_session.inspect
      end
    end
  end

  def current_user_has_unconfirmed_email?
    return false if controller_name == 'presenter_steps' && action_name == 'new_presenter_profile'
    return false unless user_signed_in?
    return false if current_user.email.blank? && current_user.unconfirmed_email.blank?
    return false if current_user.email_changed? || current_user.unconfirmed_email_changed?

    # could be twitter user until email is given
    if current_user.email.blank? && current_user.unconfirmed_email.blank?
      return false
    end

    !current_user.confirmed? || current_user.unconfirmed_email.present?
  end

  def formatted_date(date, day_name = false)
    date = date.in_time_zone(current_user.timezone) if current_user
    date_format = (current_user&.am_format? || !current_user) ? "#{day_name ? '%a, ' : ''}%b %d %l:%M %p" : "#{day_name ? '%a, ' : ''}%b %d %k:%M"
    date.strftime(date_format)
  end

  def time_with_tz_in_chosen_format(time, day_name = true)
    am_format = "#{day_name ? 'ddd, ' : ''}MMM D YYYY h:mm a"
    pm_format = "#{day_name ? 'ddd, ' : ''}MMM D YYYY H:mm"

    if user_signed_in?
      time = time.in_time_zone(current_user.timezone)
      format = current_user.try(:am_format?) ? am_format : pm_format
    else
      format = am_format
    end

    %(<abbr class="datetime" data-iso8601="#{time.iso8601}" data-format="#{format}">#{formatted_date(time,
                                                                                                     day_name)}</abbr>).html_safe
  end

  def timeForInteractive(time, day_name = true)
    am_format = 'MMM D h:mm a'
    pm_format = 'MMM D H:mm'

    if user_signed_in?
      time = time.in_time_zone(current_user.timezone)
      format = current_user.try(:am_format?) ? am_format : pm_format
    else
      format = am_format
    end

    %(<abbr class="datetime" data-iso8601="#{time.iso8601}" data-format="#{format}">#{formatted_date(time,
                                                                                                     day_name)}</abbr>).html_safe
  end

  # NOTE: goal of this method is to add some more interactivity into views counter in shared/{session,channel,user} templates
  # (highly requested featured by Alex and Maryam)
  def render_shared_model_with_live_views_counter(*args)
    model = args.last.fetch(:session) do
      args.last.fetch(:channel) do
        args.last.fetch(:user) do
          args.last.fetch(:recording, :not_found)
        end
      end
    end
    precompiled = render(*args)
    precompiled.gsub(':views_replacement_placeholder:', short_number(model.views_count)).html_safe
  end

  def short_number(count)
    number_to_human(count.to_i, units: { thousand: 'k', million: 'm' }).to_s.delete(' ')
  end

  # TODO: - cache it
  def display_warning_about_pending_changed_start_at?
    return false unless user_signed_in?

    if @session.present?
      return true if @session.livestreamers.where(participant: current_user.participant,
                                                  status: 'pending_changed_start_at').present?
      return true if @session.session_participations.where(participant: current_user.participant,
                                                           status: 'pending_changed_start_at').present?
    end
  end

  def degradable_link_to(*args, &block)
    if user_signed_in? || args.first == '#'
      if block
        return link_to(*args, &block)
      else
        return link_to(*args)
      end
    end

    path = args.detect { |arg| arg.include?('/') }
    if (hash = args.find { |arg| arg.is_a?(Hash) })

      # "Become a presenter" CTA is handled via referer during registration
      if path == wizard_v2_path
        hash['data-target'] = '#loginPopup'
        hash['data-toggle'] = 'modal'
      else
        redirect_back_to = path
        if hash[:method] == :post || hash[:method] == :put || hash[:remote] == true
          redirect_back_to = path.gsub('/toggle_follow', '').gsub('/toggle_like', '').gsub('/toggle_wishlist_item', '')
        end

        redirect_back_to.gsub!('/preview_share.js', '')
        redirect_back_to.gsub!('/preview_share', '')

        # NOTE: - data-target is automatically replaced if user has previously logged in from that device(localStorage check)
        hash.merge!('data-target' => '#loginPopup',
                    'data-toggle' => 'modal',
                    class: "#{hash[:class]} #{DEGRADABLE_LINK_CLASS}",
                    onclick: "javascript:redirect_back_to_after_signup('#{redirect_back_to}'); return false")
      end
    else
      redirect_back_to = path

      redirect_back_to.gsub!('/toggle_follow', '')
      redirect_back_to.gsub!('/toggle_like', '')
      redirect_back_to.gsub!('/toggle_wishlist_item', '')
      redirect_back_to.gsub!('/preview_share.js', '')
      redirect_back_to.gsub!('/preview_share', '')

      # NOTE: - data-target is automatically replaced if user has previously logged in from that device(localStorage check)
      args.push('data-target' => '#loginPopup',
                'data-toggle' => 'modal',
                class: DEGRADABLE_LINK_CLASS,
                onclick: "javascript:redirect_back_to_after_signup('#{redirect_back_to}'); return false")
    end

    new_args = args.dup
    args.detect { |el| el.to_s.include?('/') }

    raw_html = if block
                 link_to(*args, &block)
               else
                 link_to(*args)
               end

    fragment = Nokogiri::HTML.parse(raw_html)
    a = fragment.css('a').first
    # otherwise CTA breaks by following to that prohibited URL
    a.xpath('//@data-method').remove
    a.xpath('//@href').remove

    a.to_html.html_safe
  end

  # You this helper if you need to pass some html part into I18n interpolation
  # Two cases:
  # 1) You have I18n scope key like "session.name" and one key, which value will be a a yielded block. E.g.
  # in yaml:
  # session:
  #  name: "Hihih %{here_is_html} hihi"
  # then
  #= translate_with_haml "session.name", :here_is_html do
  #  %div Here comes a html which will be assigned to :here_is_html key and passed to I18n
  # 2) You have I18n scope key like "session.name" and more than one key for interpolation. E.g.
  # in yaml:
  # session:
  #  name: "Hihih %{here_is_html} hihi %{some_another_key}"
  # then
  #= translate_with_haml "session.name", {some_another_key: "Some value"}, :here_is_html do
  #  %div Here comes a html which will be assigned to :here_is_html key and passed to I18n
  def translate_with_haml(*args, &block)
    translate_key = args[0]
    if args[1].is_a?(Hash)
      options = args[1]
      block_key = args[2]
    else
      options = {}
      block_key = args[1]
    end
    options[block_key] = capture_haml(&block)
    I18n.t(translate_key, **options).html_safe
  end

  private

  def rejected_invitation?(abstract_session)
    Rails.cache.fetch("#{__method__}/#{abstract_session.cache_key}/#{current_user.id}") do
      rejected_immersive_participant_invitation = current_user.participant.present? ? \
        abstract_session.session_invited_immersive_participantships.where(participant: current_user.participant).rejected.present? : \
        false
      return true if rejected_immersive_participant_invitation

      rejected_livestream_participant_invitation = current_user.participant.present? ? \
        abstract_session.session_invited_livestream_participantships.where(participant: current_user.participant).rejected.present? : \
        false
      return true if rejected_livestream_participant_invitation

      rejected_co_presenter_invitation = current_user.presenter.present? ? \
        abstract_session.session_invited_immersive_co_presenterships.where(presenter: current_user.presenter).rejected.present? : \
        false
      rejected_co_presenter_invitation
    end
  end

  def mobile_Check
    if browser.platform.ios?
      'ios_device mobile_device'
    elsif browser.platform.android?
      'android_device mobile_device'
    end
  end

  def customize_logo_url
    return nil if request.original_fullpath == '/landing' || request.original_fullpath.include?('/pages')

    @current_organization&.company_setting&.logo_image&.url
  end

  def customize_css
    @current_organization&.company_setting&.custom_styles
  end

  def organization_custom_logo_url
    @organization&.company_setting&.logo_image&.url
  end

  def organization_custom_channel_link
    @organization&.company_setting&.logo_channel_link
  end

  def organization_custom_css
    @organization&.company_setting&.custom_styles
  end

  def list_of_themes
    SystemTheme.all.map { |theme| theme.as_json.html_safe }.to_json
  end

  def list_of_templates
    PageBuilder::SystemTemplate.all.map(&:as_json).to_json
  end

  def current_theme_customs_css
    theme = SystemTheme.includes(:system_theme_variables).find_by(is_default: true)
    theme ||= SystemTheme.includes(:system_theme_variables).first
    theme&.custom_css
  end

  # def current_theme_json
  #   theme = SystemTheme.includes(:system_theme_variables).find_by(is_default: true)
  #   unless theme
  #     theme = SystemTheme.includes(:system_theme_variables).first
  #   end
  #   theme.as_json.html_safe
  # end

  def current_theme_css
    theme = SystemTheme.includes(:system_theme_variables).find_by(is_default: true)
    theme ||= SystemTheme.includes(:system_theme_variables).first
    return '' unless theme

    theme.system_theme_variables.map do |var|
      "--#{var['property']}: #{var['value']};"
    end.join("\n")
  end

  def aspect_ration_percentage(height, width)
    h = height.to_f
    w = width.to_f
    w.positive? ? (h / w) * 100 : nil
  end

  def video_container_width(source)
    right_sidebar_width = 408
    result_width = source.width.to_i + right_sidebar_width
    (result_width < 1700) ? result_width : 1700
  end

  def logo_size
    config = Rails.application.credentials.frontend[:logo_size]
    config == 'default' ? 'logo' : "logo_#{config}"
  end
end
