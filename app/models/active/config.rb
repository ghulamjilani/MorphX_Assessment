# frozen_string_literal: true

class Active::Config
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :default_config, :string
  attribute :overridden_config, :string
  attribute :current_config, :string
  attribute :env, :string

  def default
    over_cred.default_config.read
  end

  def overridden
    over_cred.overridden_config.read
  end

  def current
    over_cred.config_yaml
  end

  def over_cred
    @over_cred ||= OverCreds.new(env || Rails.env, Rails.env.development?)
  end
end
