$ ->
  console.log "ON"
  sp = getSpotifyApi(1)
  models = sp.require("sp://import/scripts/api/models")
  player = models.player

  currentTrack = player.track

  console.log currentTrack
  console.log "Currently shipping to #{currentTrack}"
  console.log $("#np")

  if currentTrack?
    $("#np").html "Currently shipping to #{currentTrack}"