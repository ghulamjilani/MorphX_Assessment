# frozen_string_literal: true

# Leave here your custom error classes
class ApplicationError < StandardError
  def initialize(msg = default_message)
    super
  end

  def default_message
    ''
  end
end

class NotInheritedError < ApplicationError
end

class InvitedUserObtainAbilityMismatchError < StandardError
  attr_reader :model_invited_to, :current_user

  def initialize(model_invited_to:, current_user:)
    @model_invited_to = model_invited_to
    @current_user     = current_user
    super('Obtain ability mismatch for invited user')
  end
end

class UnsupportedBrowserError < StandardError
end

class StaleNearestAbstractSessionCache < StandardError
end

class AccessForbiddenError < ApplicationError
  def default_message
    I18n.t('error_classes.access_forbidden.message')
  end
end

class NotAuthorizedError < ApplicationError
  def default_message
    I18n.t('error_classes.not_authorized.message')
  end
end

class AbstractMethodNotInheritedError < ApplicationError
  def default_message
    I18n.t('error_classes.abstract_method_not_inherited.message')
  end
end
