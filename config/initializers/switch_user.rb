# frozen_string_literal: true

SwitchUser.setup do |config|
  # provider may be :devise, :authlogic, :clearance, :restful_authentication, :sorcery, or :session
  config.provider = :devise

  # available_users is a hash,
  # key is the model name of user (:user, :admin, or any name you use),
  # value is a block that return the users that can be switched.
  config.available_users = { user: -> { User.order('email ASC') } }

  # available_users_identifiers is a hash,
  # keys in this hash should match a key in the available_users hash
  # value is the name of the identifying column to find by,
  # defaults to id
  # this hash is to allow you to specify a different column to
  # expose for instance a username on a User model instead of id
  config.available_users_identifiers = { user: :id }

  # available_users_names is a hash,
  # keys in this hash should match a key in the available_users hash
  # value is the column name which will be displayed in select box
  config.available_users_names = { user: :email_with_display_name }

  # controller_guard is a block,
  # if it returns true, the request will continue,
  # else the request will be refused and returns "Permission Denied"
  # if you switch from "admin" to user, the current_user param is "admin"
  config.controller_guard = ->(_current_user, _request) { true }

  # view_guard is a block,
  # if it returns true, the switch user select box will be shown,
  # else the select box will not be shown
  # if you switch from admin to "user", the current_user param is "user"
  # TODO - you need to strengten this condition once we have real users
  #       you may need to check env and if current_user is part of our team
  config.view_guard = ->(_current_user, _request) { true }

  # redirect_path is a block, it returns which page will be redirected
  # after switching a user.
  config.redirect_path = ->(request, _params) { request.referer || '/' }

  # helper_with_guest is a boolean value, if it set to false
  # the guest item in the helper won't be shown
  config.helper_with_guest = true

  # false = login from one scope to another and you are logged in only in both scopes
  # true = you are logged only into one scope at a time
  config.login_exclusive = true

  # switch_back allows you to switch back to a previously selected user. See
  # README for more details.
  config.switch_back = false
end
