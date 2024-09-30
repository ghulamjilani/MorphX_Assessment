# frozen_string_literal: true

module ControllerConcerns
  module TracksViews
    extend ActiveSupport::Concern

    def track_view(obj, message = nil, opts = {})
      unless obj.respond_to?(:viewable?) && obj.viewable?
        Airbrake.notify("#{obj.class} is not viewable!", parameters: view_params)
        return
      end

      return unless should_count_view?(opts)

      if unique_instance?(obj, opts[:unique])
        ViewableJobs::CreateViewJob.perform_async(view_params({ message: message,
                                                                viewable_id: obj.id,
                                                                viewable_type: obj.class.name }))
      end
    end

    protected

    # creates a statment hash that contains default values for creating a view via an AR relation.
    def view_params(query_params = {})
      filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      query_params.reverse_merge!(
        controller_name: controller_name,
        action_name: action_name,
        user_id: viewer_user_id,
        request_id: request.request_id,
        ip_address: request_ip_address,
        user_agent: request.user_agent,
        session_hash: request.session_options[:id],
        referrer: request.referer,
        params: filter.filter(params_hash)
      ).stringify_keys
    end

    private

    def should_count_view?(opts)
      condition_true?(opts[:if]) && condition_false?(opts[:unless])
    end

    def condition_true?(condition)
      condition.present? ? conditional?(condition) : true
    end

    def condition_false?(condition)
      condition.present? ? !conditional?(condition) : true
    end

    def conditional?(condition)
      condition.is_a?(Symbol) ? send(condition) : condition.call
    end

    def params_hash
      request.params.except(:controller, :action, :id)
    end

    # use both @current_user and current_user helper
    def viewer_user_id
      user_id = begin
        @current_user ? @current_user.id : nil
      rescue StandardError
        nil
      end
      if user_id.blank?
        user_id = begin
          current_user ? current_user.id : nil
        rescue StandardError
          nil
        end
      end
      user_id
    end

    def request_ip_address
      request.headers['HTTP_CF_CONNECTING_IP'] || request.headers['HTTP_X_FORWARDED_FOR'] || request.remote_ip
    end

    def user_id_or_ip
      viewer_user_id || request_ip_address
    end

    def unique_instance?(viewable, unique_opts)
      unique_opts.blank? || !viewable.unique_view_exists?(user_id_or_ip)
    end
  end
end
