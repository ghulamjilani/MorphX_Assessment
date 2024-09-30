do ->
  'use strict'
  #full-screen video body class - jplayer-fullscreen
  mediaIcons =
    'image': 'icon-file-image'
    'audio': 'VideoClientIcon-glyph-7'
    'video': 'icon-glyph-8'
    'file' : 'icon-doc'

  Handlebars.registerHelper 'mediaIcon', ->
    type = _(_(mediaIcons).keys()).find (type)=>
      @mime_type.indexOf(type) is 0
    type or= 'file'
    mediaIcons[type]

  mediator = {}
  _.extend mediator, Backbone.Events

  class MediaResourceUrl extends Backbone.Model
    url: ->
      "/lobbies/#{window.Immerss.roomId}/dropbox_media_url?dropbox_material_id=#{@id}"

  class MediaResource extends Backbone.Model
    initialize: ->
      @resourceUrl = new MediaResourceUrl({id: @id})

    getMediaUrl: ->
      @resourceUrl.fetch()

    downloadUrl: ->
      "/lobbies/#{Immerss.roomId}/get_dropbox_media?dropbox_material_id=#{@id}"

  class MediaResources extends Backbone.Collection
    model: MediaResource

    nextTrack: ->
      currentIndex = @indexOf @currentTrack
      if currentIndex + 1 is @length
        @setCurrentTrack(@at(0))
      else
        @setCurrentTrack(@at(currentIndex + 1))
      @currentTrack

    prevTrack: ->
      currentIndex = @indexOf @currentTrack
      if currentIndex is 0
        @setCurrentTrack(@at(@length - 1))
      else
        @setCurrentTrack(@at(currentIndex - 1))
      @currentTrack

    setCurrentTrack: (track)->
      @currentTrack = track

  class MediaPlayerView extends Backbone.View
    region: "#mediaPlayerContainer"
    listSelector: ".media-list"
    events:
      "click .prev-track":   "gotoPrevTrack"
      "click .next-track":   "gotoNextTrack"
      "click .close-player": "closePlayer"

    initialize: ->
      @template = HandlebarsTemplates['lobbies/media_player_main']()
      @currentPlayerView = null

      @$region = $(@region)
      @viewsByCid = {}

      mediator.on "play-media", @initPlayerView, @
      mediator.on "play-media", @markActiveTrack, @

      @render()
      #Open first track on init
      @gotoNextTrack()

    renderAllItems: ->
      for item in @collection.models
        @renderItem(item)

    renderItem: (item)->
      view = @viewsByCid[item.cid]
      unless view
        view = new MediaItemView model: item
        @viewsByCid[item.cid] = view
      @$listSelector.append(view.$el)
      view.render()

    getTemplateData: ->
      data = {}
      data

    getTemplateFunction: ->
      Handlebars.compile(@template)

    render: ->
      templateFunc = @getTemplateFunction()
      html = templateFunc(@getTemplateData())
      @$el.html(html)
      @$listSelector = @$(@listSelector)
      @renderAllItems()
      @$region.append(@$el)

    dispose: ->
      return if @disposed

      @stopListening @collection
      if @currentPlayerView
        @currentPlayerView.dispose()

      @$el.remove()

      mediator.off()

      properties = ['el', '$el', 'collection', 'template', '$region', '$listSelector', 'viewsByCid', 'currentPlayerView']
      delete this[prop] for prop in properties

      @disposed = true

    initPlayerView: (model)->
      if @currentPlayerView
        @currentPlayerView.dispose()

      klass = @getPlayerKlass(model)
      @currentPlayerView = new klass {model, $region: @$('.MediaBoxWrapper')}

    getPlayerKlass: (model)->
      mime_type = model.get("mime_type")
      mimeTypes =
        'image': ImagePlayerView
        'audio': AudioPlayerView
        'video': VideoPlayerView
        'file' : FilePlayerView
      type = _(_(mimeTypes).keys()).find (type)->
        mime_type.indexOf(type) is 0
      type or= 'file'
      mimeTypes[type]

    gotoPrevTrack: (event)->
      event?["preventDefault"]()
      return if @collection.length is 0
      track = @collection.prevTrack()
      @initPlayerView track
      @markActiveTrack track

    gotoNextTrack: (event)->
      event?["preventDefault"]()
      return if @collection.length is 0
      track = @collection.nextTrack()
      @initPlayerView track
      @markActiveTrack track

    markActiveTrack: (model)->
      for cid, view of @viewsByCid
        view.$el.removeClass("active")
      viewEl = @viewsByCid[model.cid].$el
      viewEl.addClass("active")
      @scrollTo(viewEl)

    scrollTo: ($target)->
      @$listSelector.scrollTo($target)

    closePlayer: ->
      $(window).trigger("close-player-tab")

  class MediaItemView extends Backbone.View
    tagName: "li"
    events:
      "click .play-media": "playMedia"

    initialize: ->
      @template = HandlebarsTemplates['lobbies/media_item'](@getTemplateData())

    getTemplateFunction: ->
      Handlebars.compile(@template)

    getTemplateData: ->
      data = @model.toJSON()
      data.name = _(data.path.split('/')).last()
      data.downloadUrl = @model.downloadUrl()
      data.canDowload = data.can_download
      data

    render: ->
      templateFunc = @getTemplateFunction()
      html = templateFunc()
      @$el.html(html)

    playMedia: (e)->
      e.preventDefault()
      mediator.trigger "play-media", @model

    dispose: ->
      return if @disposed

      @off()
      @$el.remove()

      properties = ['el', '$el', 'model', 'template']
      delete this[prop] for prop in properties

      @disposed = true

  class PlayerNavigationView extends Backbone.View
    initialize: (options)->
      @$region = options.$region
      @canPlay = options.canPlay
      @mediaType = options.mediaType
      @template = HandlebarsTemplates['lobbies/player_nav'](@getTemplateData())

      @render()

    getTemplateFunction: ->
      Handlebars.compile(@template)

    getTemplateData: ->
      data = {}
      data.canPlay = @canPlay
      data.isPausable = (@mediaType is 'video' or @mediaType is 'audio') and @canPlay
      data

    render: ->
      templateFunc = @getTemplateFunction()
      html = templateFunc()
      @$el.html(html)
      @$region.append(@$el)

    dispose: ->
      return if @disposed

      @off()
      @$el.remove()

      properties = ['el', '$el', 'model', 'template', '$region', 'options', 'canPlay', 'mediaType']
      delete this[prop] for prop in properties

      @disposed = true

  class AbstractPlayerView extends Backbone.View
    initialize: (options)->
      @$region = options.$region
      @setCanPlay()
      @getMediaUrl()
      @setTemplate()
      @render()

    getTemplateFunction: ->
      Handlebars.compile(@template)

    getTemplateData: ->
      data = @model.toJSON()
      data.name = _(data.path.split('/')).last()
      data.isLoaded = @isLoaded
      data.mediaUrl = @model.resourceUrl.get('media_url')
      data.canPlay = @canPlay
      data

    render: ->
      templateFunc = @getTemplateFunction()
      html = templateFunc(@getTemplateData())
      @$el.html(html)
      @$region.append(@$el)
      @initNavigationView()

    dispose: ->
      return if @disposed

      @off()
      @stopListening @model.resourceUrl

      @navigationView.dispose()
      @$el.remove()

      properties = ['el', '$el', 'model', 'template', '$region', 'isLoaded', 'navigationView']
      delete this[prop] for prop in properties

      @disposed = true

    setTemplate: ->
      throw "Abstract class must be overridden."

    getMediaUrl: ->
      if @canPlay
        @isLoaded = false
        @listenTo @model.resourceUrl, "sync", @play

        @model.getMediaUrl()
      else
        @isLoaded = true

    play: ->
      @isLoaded = true
      @render()
      @initPlayer()

    initPlayer: ->

    initNavigationView: ->
      if @navigationView
        @navigationView.dispose()
      @navigationView = new PlayerNavigationView({$region: @$('.MediaNav'), canPlay: @canPlay, mediaType: @mediaType})

    setCanPlay: ->
      @canPlay = true

  class VideoPlayerView extends AbstractPlayerView
    mediaType: 'video'
    setTemplate: ->
      @template = HandlebarsTemplates['lobbies/video_audio_player'](@getTemplateData())

    initPlayer: ->
      format = _(_(@model.get("path").split('/')).last().split(".")).last()
      media = {}
      media[format] = @model.resourceUrl.get('media_url')
      self = this
      @$(".jPlayer").jPlayer
        ready: ->
          $(this).jPlayer( "setMedia", media ).jPlayer("play")
          self.makeVolbarDraggable(self.$(".MediaSoundV .MeD-overlay"), $(this))
        solution: "html,flash"
        supplied: format
        cssSelectorAncestor: @$el
        cssSelector:
          play: ".MeD-play"
          pause: ".MeD-pause"
          noSolution: ".err-play"
          volumeBar: ".MediaSoundV .MeD-overlay"
          volumeBarValue: ".MediaSoundV .sound-val"
          duration: ".duration"
          currentTime: ".current-time"
          seekBar: ".progress-bar"
          playBar: ".progress-bar-val"
          fullScreen: ".MeD-fulscr"
          restoreScreen: ".MeD-restore-screen"
        size: @playerSize()


    dispose: ->
      return if @disposed
      $(window).unbind "mousemove.jPlayer"
      $(window).unbind "mouseup.jPlayer"
      $(window).unbind "mousedown.jPlayer"
      @$(".jPlayer").jPlayer('destroy')
      super

    getTemplateData: ->
      data = super
      data.isVideo = @mediaType is 'video'
      data

    setCanPlay: ->
      format = _(_(@model.get("path").split('/')).last().split(".")).last()
      @canPlay = _($.jPlayer.prototype.format).keys().indexOf(format) isnt -1

    makeVolbarDraggable: ($volumeBar, $player)->
      $(window).on "mousedown.jPlayer", $volumeBar, (e)->
        parentOffset = $volumeBar.offset()
        width = $volumeBar.width()
        $(window).bind "mousemove.jPlayer", (e) ->
          x = e.pageX - parentOffset.left
          volume = x / width
          if volume > 1
            $player.jPlayer "volume", 1
          else if volume <= 0
            $player.jPlayer "mute"
          else
            $player.jPlayer "volume", volume
            $player.jPlayer "unmute"
          return

        false
      $(window).on "mouseup.jPlayer", ->
        $(window).unbind "mousemove.jPlayer"
        return

    playerSize: ->
      { width: "260px", height: "270px", cssClass: "jp-video-270p" }

  class AudioPlayerView extends VideoPlayerView
    mediaType: 'audio'
    playerSize: ->
      { width: "0px", height: "0px", cssClass: "" }

  class ImagePlayerView extends AbstractPlayerView
    mediaType: 'image'
    setTemplate: ->
      @template = HandlebarsTemplates['lobbies/image_player'](@getTemplateData())

  class FilePlayerView extends AbstractPlayerView
    mediaType: 'file'
    setTemplate: ->
      @template = HandlebarsTemplates['lobbies/file_player'](@getTemplateData())

    getMediaUrl: ->
      #Stub. We don't need it for files which we can't play

  $ ->
    if _(window.Immerss.dropboxMaterials).isArray()
      mediaPlayerView = null
      $(window).on "media-player-start", ->
        if mediaPlayerView
          mediaPlayerView.dispose()
        mediaPlayerView = new MediaPlayerView( collection: new MediaResources( window.Immerss.dropboxMaterials, { silent: false } ) )

      $(window).on "media-player-stop", ->
        if mediaPlayerView
          mediaPlayerView.dispose()
        mediaPlayerView = null
