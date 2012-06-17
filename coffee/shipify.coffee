
$ ->
  window.S =
    serverURL: 'http://shipify-server.herokuapp.com/'

  sp = getSpotifyApi(1)
  models = sp.require("sp://import/scripts/api/models")
  player = models.player


  class Theme
    constructor: (track_uri, start, stop) ->
      @track = models.Track.fromURI(track_uri)
      @start = start
      @stop = stop

      @fadeTime = 1500

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
      # Does not currently work
      # http://stackoverflow.com/questions/10822979/change-volume-with-spotify-app-api
      timeInterval = @fadeTime/10
      console.log @fadeTime
      for level in [10..1]
        do (level) =>
          setTimeout =>
            player.volume = 0.1*level
            console.log 0.1*level
          , timeInterval*level
      setTimeout callback, @fadeTime

  themes =
    # nottombrown: new Theme('spotify:track:3MrRksHupTVEQ7YbA0FsZK', 13000, 54000)
    nottombrown: new Theme('spotify:track:2BY7ALEWdloFHgQZG6VMLA', 12000, 44000)
    facedog: new Theme('spotify:track:2BY7ALEWdloFHgQZG6VMLA', 12000, 44000)
    waxman: new Theme('spotify:track:2BY7ALEWdloFHgQZG6VMLA', 12000, 44000)

  # Loops
  #
  #
  #
  updateCurrentlyPlaying = ->
    if !S.playingTheme
      currentTrack = player.track

      S.position = player.position
      S.track = currentTrack
      # console.log S.position

      if currentTrack?
        $("#np").html "Currently shipping to #{currentTrack}"

  setInterval updateCurrentlyPlaying, 200


  socket = io.connect(S.serverURL)
  socket.on 'connect', () ->
    console.log "Connected!"


  socket.on 'commit', (data) ->
    console.log(data)
    commit = data

    username = commit.username
    theme = themes[username]
    if theme?
      theme.play()
    # socket.emit 'my other event', { my: 'data' }



  # checkForNewCommits()



  # Buttons
  #
  #
  #
  $('#play-trex').click ->
    themes.nottombrown.play()


  $('#play-cdog').click ->
    themes.facedog.play()
