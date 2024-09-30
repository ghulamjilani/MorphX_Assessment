# frozen_string_literal: true

class VisitorSourcesController < ActionController::Base
  def create
    unless current_user
      @vs = begin
        VisitorSource.find_by(visitor_id: cookies.permanent[:visitor_id])
      rescue StandardError
        nil
      end
      if !@vs || !@vs.first
        vs_attrs = {
          refc: cookies.permanent.signed[:refc],
          current: cookies[:sbjs_current],
          current_add: cookies[:sbjs_current_add],
          first: cookies[:sbjs_first],
          first_add: cookies[:sbjs_first_add],
          session: cookies[:sbjs_session],
          udata: cookies[:sbjs_udata]
        }
        VisitorSource.track_visitor(cookies.permanent[:visitor_id], vs_attrs)
      end
    end
    head :ok
  end
end
