window.S ||= {} # initialized in settings.js

# Format is github_username: ['spotify_track_uri', start_in_ms, stop_in_ms]
S.defaultThemes =
  nottombrown: ['spotify:track:0GugYsbXWlfLOgsmtsdxzg', 12000, 50000]
  facedog: ['spotify:track:2BY7ALEWdloFHgQZG6VMLA', 12000, 44000]
  waxman: ['spotify:track:3MrRksHupTVEQ7YbA0FsZK', 12000, 44000]

$ ->

  # // The server running shipify-server
  S.serverURL = JSON.parse localStorage.getItem('serverURL')
  S.serverURL ||= 'http://shipify-server.herokuapp.com/'

  console.log S

  themeTemplate = Haml("""
  %tr
    %td.username=username
    %td.themesong=themesong
    %td.range=range
    %td
      %a.preview<> play
      |
      %a.remove<> remove
  """)


  sp = getSpotifyApi(1)
  models = sp.require("sp://import/scripts/api/models")
  player = models.player


  class ThemeList extends Backbone.Model
    initialize: ->
      @on 'change', @persist

    persist: =>
      localStorage.setItem('themeList', JSON.stringify(@toJSON()))

    renderThemeViews: =>
      console.log TL.toJSON()
      $('.themesongs tbody').empty()

      @themes = {}
      for username, song of TL.toJSON()
        do ( username, song) =>
          @themes[username] = new ThemeView(song[0], song[1], song[2], username)


  # Initialize Themelist
  Boot = JSON.parse localStorage.getItem('themeList')
  Boot = S.defaultThemes
      

  TL = new ThemeList(Boot)

  # TL.persist()

  class ThemeView extends Backbone.View
    constructor: (track_uri, start, stop, username) ->
      @track = models.Track.fromURI(track_uri)
      @start = start
      @stop = stop
      @username = username

      @fadeTime = 1500
      @render()

    render: =>
      @el = $ themeTemplate
        username: @username
        themesong: @track
        range: "#{@start/1000}s - #{@stop/1000}s"

      @el.find('.preview').click =>
        @play()
      @el.find('.remove').click =>
        @remove()
      @el.appendTo $('.themesongs tbody')

    remove: =>
      console.log "Removed"
      TL.unset(@username)
      console.log TL
      @el.hide()

    play: =>
      S.playingTheme = true
      player.track = @track
      setTimeout @end, (@stop-@start)

      setCorrectPosition = =>
        # Give us some time to load the new track
        if player.track.name != @track.name
          setTimeout ->
            setCorrectPosition()
          , 100
        else
          player.position = @start

      setCorrectPosition()

    end: =>
      player.track = S.track

      # Give us some time to load the new track
      setCorrectPosition = =>
        player.position = S.position

        if player.track.name != S.track.name
          setTimeout ->
            setCorrectPosition()
          , 100
        else
          S.playingTheme = false

      setCorrectPosition()

    fadeOut: (callback=->)=>
      # Volume changing does not currently work
      # http://stackoverflow.com/questions/10822979/change-volume-with-spotify-app-api
      timeInterval = @fadeTime/10
      for level in [10..1]
        do (level) =>
          setTimeout =>
            player.volume = 0.1*level
            console.log 0.1*level
          , timeInterval*level
      setTimeout callback, @fadeTime

  # Rendering
  #
  #
  #
  TL.renderThemeViews()

  # Loop
  #
  #
  #
  updateCurrentlyPlaying = ->
    if !S.playingTheme
      currentTrack = player.track

      S.position = player.position
      S.track = currentTrack

      if currentTrack?
        $("#np").html "#{currentTrack}"

  setInterval updateCurrentlyPlaying, 200


  # Socket.io
  #
  #
  #
  socket = io.connect(S.serverURL)
  socket.on 'connect', () ->
    console.log "Connected!"

  socket.on 'commit', (data) ->
    commit = data

    username = commit.username
    theme = TL.themes[username]
    if theme?
      theme.play()

  # Tabs
  #
  #
  #

  tabs = ->
    args = models.application.arguments
    current = $("##{args[0]}")
    sections = $(".section").hide()
    current.show()

  tabs()
  models.application.observe models.EVENT.ARGUMENTSCHANGED, tabs


  # Adding a new themesong
  #
  #
  #
  $("#new button").click (e) ->
    console.log "New theme"
    theme =
      username: $("#new .username").val()
      uri: $("#new .uri").val()
      start: parseInt $("#new .start").val()
      stop: parseInt $("#new .stop").val()

    TL.set(theme.username, [theme.uri, theme.start, theme.stop])
    TL.renderThemeViews()
    e.preventDefault()
    return false


  # Updating settings
  #
  #
  #
  $("#settings .server").val(S.serverURL)
  $("#settings .server").change (e) ->
    console.log "New server"
    S.serverURL = $(@).val()

    localStorage.setItem('serverURL', JSON.stringify(S.serverURL))

    e.preventDefault()
    return false
