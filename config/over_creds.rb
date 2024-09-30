# frozen_string_literal: true

class OverCreds
  def initialize(env, local = false)
    @key_path = "#{Rails.root}/config/credentials/master.#{env}.key"
    @default_config_path = "#{Rails.root}/config/credentials/credentials.#{env}.yml.enc"

    @overridden_config_path = if local
                                "#{Rails.root}/config/credentials/credentials.over.#{env}.yml.enc"
                              else
                                root = Rails.root.to_s.split('/')[0..-3].join('/')
                                "#{root}/shared/config/credentials/credentials.over.#{env}.yml.enc"
                              end
  end

  def create_configs
    File.binwrite(@key_path, ActiveSupport::EncryptedConfiguration.generate_key) unless File.exist?(@key_path)
    default_config.write('') unless File.exist?(@default_config_path)
    overridden_config.write('') unless File.exist?(@overridden_config_path)
  end

  def default_config
    ActiveSupport::EncryptedConfiguration.new(
      config_path: @default_config_path,
      key_path: @key_path,
      env_key: 'RAILS_MASTER_KEY',
      raise_if_missing_key: false
    )
  end

  def overridden_config
    ActiveSupport::EncryptedConfiguration.new(
      config_path: @overridden_config_path,
      key_path: @key_path,
      env_key: 'RAILS_MASTER_KEY',
      raise_if_missing_key: false
    )
  end

  def config_yaml
    default_config.config.deep_merge(overridden_config.config).to_yaml
  end

  def config
    hash = default_config.config.deep_merge(overridden_config.config)
    ActiveSupport::InheritableOptions.new(hash)
  end

  def write(yaml:)
    overridden_config.write(yaml)
  end
end
