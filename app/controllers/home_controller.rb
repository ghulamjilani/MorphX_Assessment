# frozen_string_literal: true

class HomeController < ApplicationController
  include ControllerConcerns::ValidatesRecaptcha

  before_action :check_return_to, only: [:index]
  before_action :set_current_organization
  layout 'application'

  def index
    # Work with us link should point to root
    # All non-logged in users clicking on logo  - Business page;
    # All logged in users (regardless creator or not) clicking on logo  - root page
    if !params[:work_with_us] && current_user
      ref = begin
        URI.parse(request.referrer)
      rescue StandardError
        nil
      end
      if ref&.host == request.host || current_user.role != 'presenter'
        return redirect_to root_path
      elsif current_user.role == 'presenter'
        return redirect_to dashboard_path
      end
    end
  end

  def discover
    load_home_index
    respond_to(&:html)
  end

  def landing
    return redirect_to root_path unless Rails.application.credentials.global[:pages][:landing]

    @plan_packages = PlanPackage.preload(:plans).where(active: true, custom: false).order(position: :asc)

    unless Rails.application.credentials.frontend[:landing][:enable_layout]
      render layout: false
    end
  end

  def support
  end

  def zoom_docs
  end

  def business
    redirect_to landing_home_path
  end

  private

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
  end

  def load_home_index
    home_store = HomePageStore.new(current_user, 30)
    # @live_now = home_store.live_now
    @upcoming = home_store.upcoming.limit(15)
    @total_upcoming = home_store.all_upcoming.count

    @channels = home_store.channels.limit(15)
    @total_channels = home_store.all_channels.count

    @creators = home_store.creators.limit(15)
    @total_creators = home_store.all_creators.count

    @replays = home_store.replays.limit(15)
    @total_replays = home_store.all_replays.count

    @companies = home_store.companies
    @total_companies = home_store.all_companies.count

    @brands = home_store.brands

    if user_signed_in? && (@contacts_to_display_in_modal = current_user.contacts_to_display_in_modal(logger_user_tag))
      # if @contacts_to_display_in_modal = Contact.all.limit(3) <= Slava, uncomment this line if you need to test/update this feature
      session['autodisplay_modal'] = DashboardHelper::FACEBOOK_CONTACT_MODAL
    end
  end
end
