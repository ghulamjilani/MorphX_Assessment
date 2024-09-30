# frozen_string_literal: true

class AbstractSessionInvitationButtonsPresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Context
  include MoneyHelper

  def initialize(options = {})
    @model_invited_to  = options[:model_invited_to]  if options[:model_invited_to]
    @current_user      = options[:current_user]      if options[:current_user]
    @ability           = options[:ability]           if options[:ability]
  end

  def accept_html
    raise 'must be overriden'
  end

  def decline_html
    raise 'must be overriden'
  end

  def prepare_obtain_links
    raise 'must be overriden'
  end

  def forcefully_close_path
    raise 'must be overriden'
  end
end
