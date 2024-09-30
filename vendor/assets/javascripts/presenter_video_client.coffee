class window.PresenterVideoClient

  constructor: (options = {}) ->
    @video_client_url = 'http://127.0.0.1:65001'
    @callback_url = "#{window.location.protocol}//#{window.location.host}/1px.gif"

    @image = new Image

    @image.onload = ->
      if typeof options.successCallback is 'function'
        options.successCallback()
    @image.onerror = ->
      if typeof options.errorCallback is 'function'
        options.errorCallback()

  open: (user_id, user_auth, session_id) ->
    @image.src = "#{@video_client_url}/user_listener?session_id=#{session_id}&user_id=#{user_id}&auth_token=#{user_auth}&url=#{@callback_url}&cache=#{@getTime()}"

  getTime: ->
    new Date().getTime()

