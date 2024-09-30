#hack for Rails 7.1
Rails.application.config.to_prepare do
  Plutus::Account.inheritance_column = :_type_disabled
end

