window.S ||= {} # initialized in settings.js
$ ->

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


  class Theme
    constructor: (track_uri, start, stop, username) ->
      @track = models.Track.fromURI(track_uri)
      @start = start
      @stop = stop
      @username = username

      @fadeTime = 1500
      @render()

    render: =>
      html = $ themeTemplate
        username: @username
        themesong: @track
        range: "#{@start/1000}s - #{@stop/1000}s"
      html.find('.preview').click =>
        @play()
      html.find('.remove').click =>
        @remove()
      html.appendTo $('.themesongs')

    remove: =>
      console.log "Removed"

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

  themes = {}

  for username, song of S.themesongs
    do (themes, username, song) ->
      themes[username] = new Theme(song[0], song[1], song[2], username)

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
    theme = themes[username]
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

