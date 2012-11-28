window.S ||= {} # initialized in settings.js

# Format is github_username: ['spotify_track_uri', start_in_ms, stop_in_ms]
S.defaultThemes =
  nottombrown: ['spotify:track:0GugYsbXWlfLOgsmtsdxzg', 12000, 54000]
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
      $('.themesongs tbody').empty()

      @themes = {}
      for username, song of TL.toJSON()
        do ( username, song) =>
          track_uri = song[0]
          start = song[1]
          stop = song[2]
          @themes[username] = new ThemeView(track_uri, new Date(start), new Date(stop), username)


  # Initialize Themelist
  Boot = JSON.parse localStorage.getItem('themeList')
  Boot ||= S.defaultThemes


  TL = new ThemeList(Boot)

  class ThemeView extends Backbone.View
    constructor: (track_uri, start, stop, username) ->
      @track_uri = track_uri + '#' + start.getMinutes() + ':' + start.getSeconds()
      @track = models.Track.fromURI(track_uri)
      @start = start
      @stop = stop
      @username = username

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
      TL.unset(@username)
      @el.hide()

    play: =>
      if !S.playingTheme
        S.playingTheme = true

        player.play(@track_uri)
        setTimeout @end, (@stop-@start)


    end: =>
      if S.playingTheme
        S.playingTheme = false
        player.playing = false

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
    if S.playingTheme
      currentTrack = player.track

      S.track = currentTrack

      if currentTrack?
        $("#np").html "#{currentTrack}"
    else
      $("#np").empty()

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

    parseTime = (time) ->
      timeRegexp = /(\d{1,2}):(\d{2})/g
      match = timeRegexp.exec(time)
      if not match
        return null
      console.log(match[1])
      console.log(match[2])
      console.log(1000 * ( 60 * parseInt(match[1]) + parseInt(match[2]) ))
      return 1000 * ( 60 * parseInt(match[1]) + parseInt(match[2]) )

    theme =
      username: $("#new .username").val()
      uri: $("#new .uri").val()
      start: parseTime $("#new .start").val()
      stop: parseTime $("#new .stop").val()

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
