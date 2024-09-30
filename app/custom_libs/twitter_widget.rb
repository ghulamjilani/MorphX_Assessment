# frozen_string_literal: true

require 'mechanize'

class TwitterWidget
  WIDGET_SEARCH_URL = 'https://twitter.com/settings/widgets/new/search?query='
  LOGIN_URL = 'https://twitter.com/login'

  def initialize(hashtag)
    @hashtag = hashtag
  end

  def get_widget_id
    login
    open_widget_page
    extract_id
  end

  private

  def login
    page = agent.get(LOGIN_URL)

    page.form_with(action: 'https://twitter.com/sessions') do |form|
      form.field_with(name: 'session[username_or_email]').value = ENV['TWITTER_USERNAME']
      form.field_with(name: 'session[password]').value = ENV['TWITTER_PASSWORD']
    end.submit
  end

  def open_widget_page
    page = agent.get(WIDGET_SEARCH_URL + CGI.escape(@hashtag))

    @response = page.form_with(id: 'widget-form').submit
  end

  def extract_id
    @response.search('#code')[0].children[1].attributes['data-widget-id'].value
  end

  def agent
    unless @agent
      @agent = Mechanize.new
      @agent.follow_meta_refresh = true
      @agent.user_agent_alias = 'Mac Mozilla'
    end
    @agent
  end
end
