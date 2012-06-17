// Generated by CoffeeScript 1.3.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  window.S || (window.S = {});

  $(function() {
    var Theme, models, player, socket, song, sp, themeTemplate, themes, updateCurrentlyPlaying, username, _fn, _ref;
    themeTemplate = Haml("%tr\n  %td.username=username\n  %td.themesong=themesong\n  %td.range=range\n  %td\n    %a.preview play");
    console.log(themeTemplate);
    sp = getSpotifyApi(1);
    models = sp.require("sp://import/scripts/api/models");
    player = models.player;
    Theme = (function() {

      function Theme(track_uri, start, stop, username) {
        this.fadeOut = __bind(this.fadeOut, this);

        this.end = __bind(this.end, this);

        this.play = __bind(this.play, this);

        this.render = __bind(this.render, this);
        this.track = models.Track.fromURI(track_uri);
        this.start = start;
        this.stop = stop;
        this.username = username;
        console.log(this.username);
        console.log(this.track);
        this.fadeTime = 1500;
        this.render();
      }

      Theme.prototype.render = function() {
        var html,
          _this = this;
        html = $(themeTemplate({
          username: this.username,
          themesong: this.track,
          range: "" + (this.start / 1000) + "s - " + (this.stop / 1000) + "s"
        }));
        html.find('.preview').click(function() {
          return _this.play();
        });
        return html.appendTo($('.themesongs'));
      };

      Theme.prototype.play = function() {
        var setCorrectPosition,
          _this = this;
        S.playingTheme = true;
        player.track = this.track;
        setTimeout(this.end, this.stop - this.start);
        setCorrectPosition = function() {
          if (player.track.name !== _this.track.name) {
            return setTimeout(function() {
              return setCorrectPosition();
            }, 100);
          } else {
            return player.position = _this.start;
          }
        };
        return setCorrectPosition();
      };

      Theme.prototype.end = function() {
        var setCorrectPosition,
          _this = this;
        player.track = S.track;
        setCorrectPosition = function() {
          player.position = S.position;
          if (player.track.name !== S.track.name) {
            return setTimeout(function() {
              return setCorrectPosition();
            }, 100);
          } else {
            return S.playingTheme = false;
          }
        };
        return setCorrectPosition();
      };

      Theme.prototype.fadeOut = function(callback) {
        var level, timeInterval, _fn, _i,
          _this = this;
        if (callback == null) {
          callback = function() {};
        }
        timeInterval = this.fadeTime / 10;
        _fn = function(level) {
          return setTimeout(function() {
            player.volume = 0.1 * level;
            return console.log(0.1 * level);
          }, timeInterval * level);
        };
        for (level = _i = 10; _i >= 1; level = --_i) {
          _fn(level);
        }
        return setTimeout(callback, this.fadeTime);
      };

      return Theme;

    })();
    themes = {};
    _ref = S.themesongs;
    _fn = function(themes, username, song) {
      return themes[username] = new Theme(song[0], song[1], song[2], username);
    };
    for (username in _ref) {
      song = _ref[username];
      _fn(themes, username, song);
    }
    updateCurrentlyPlaying = function() {
      var currentTrack;
      if (!S.playingTheme) {
        currentTrack = player.track;
        S.position = player.position;
        S.track = currentTrack;
        if (currentTrack != null) {
          return $("#np").html("" + currentTrack);
        }
      }
    };
    setInterval(updateCurrentlyPlaying, 200);
    socket = io.connect(S.serverURL);
    socket.on('connect', function() {
      return console.log("Connected!");
    });
    socket.on('commit', function(data) {
      var commit, theme;
      console.log(data);
      commit = data;
      username = commit.username;
      theme = themes[username];
      if (theme != null) {
        return theme.play();
      }
    });
    $('#play-trex').click(function() {
      return themes.nottombrown.play();
    });
    return $('#play-cdog').click(function() {
      return themes.facedog.play();
    });
  });

}).call(this);
