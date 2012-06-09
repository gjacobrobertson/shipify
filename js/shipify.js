  window.onload = function() {
    /* Instantiate the global sp object; include models & views */
    var sp = getSpotifyApi(1);
    var models = sp.require("sp://import/scripts/api/models");
    var player = models.player;

    // Get the track that is currently playing
    var currentTrack = player.track;

    var currentHTML = document.getElementById('np');
    // if nothing currently playing
    if (currentTrack == null) {
        currentHTML.innerHTML = 'No track currently playing';
    } else {
        currentHTML.innerHTML = 'Currently shipping to: ' + currentTrack;
    }
}