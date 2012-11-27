// Generated by CoffeeScript 1.4.0
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  window.S || (window.S = {});

  S.defaultThemes = {
    nottombrown: ['spotify:track:0GugYsbXWlfLOgsmtsdxzg', 12000, 50000],
    facedog: ['spotify:track:2BY7ALEWdloFHgQZG6VMLA', 12000, 44000],
    waxman: ['spotify:track:3MrRksHupTVEQ7YbA0FsZK', 12000, 44000]
  };

  $(function() {
    var Boot, TL, ThemeList, ThemeView, models, player, socket, sp, tabs, themeTemplate, updateCurrentlyPlaying;
    S.serverURL = JSON.parse(localStorage.getItem('serverURL'));
    S.serverURL || (S.serverURL = 'http://shipify-server.herokuapp.com/');
    console.log(S);
    themeTemplate = Haml("%tr\n  %td.username=username\n  %td.themesong=themesong\n  %td.range=range\n  %td\n    %a.preview<> play\n    |\n    %a.stop<> stop\n    |\n    %a.remove<> remove");
    sp = getSpotifyApi(1);
    models = sp.require("sp://import/scripts/api/models");
    player = models.player;
    ThemeList = (function(_super) {

      __extends(ThemeList, _super);

      function ThemeList() {
        this.renderThemeViews = __bind(this.renderThemeViews, this);

        this.persist = __bind(this.persist, this);
        return ThemeList.__super__.constructor.apply(this, arguments);
      }

      ThemeList.prototype.initialize = function() {
        return this.on('change', this.persist);
      };

      ThemeList.prototype.persist = function() {
        return localStorage.setItem('themeList', JSON.stringify(this.toJSON()));
      };

      ThemeList.prototype.renderThemeViews = function() {
        var song, username, _ref, _results,
          _this = this;
        $('.themesongs tbody').empty();
        this.themes = {};
        _ref = TL.toJSON();
        _results = [];
        for (username in _ref) {
          song = _ref[username];
          _results.push((function(username, song) {
            var start, stop, track_uri;
            track_uri = song[0];
            start = song[1];
            stop = song[2];
            return _this.themes[username] = new ThemeView(track_uri, start, stop, username);
          })(username, song));
        }
        return _results;
      };

      return ThemeList;

    })(Backbone.Model);
    Boot = JSON.parse(localStorage.getItem('themeList'));
    Boot || (Boot = S.defaultThemes);
    TL = new ThemeList(Boot);
    ThemeView = (function(_super) {

      __extends(ThemeView, _super);

      function ThemeView(track_uri, start, stop, username) {
        this.fadeOut = __bind(this.fadeOut, this);

        this.end = __bind(this.end, this);

        this.play = __bind(this.play, this);

        this.remove = __bind(this.remove, this);

        this.render = __bind(this.render, this);

        var lpad, minutes, seconds;
        lpad = function(value, padding) {
          var i, zeroes, _i;
          zeroes = "0";
          for (i = _i = 1; 1 <= padding ? _i <= padding : _i >= padding; i = 1 <= padding ? ++_i : --_i) {
            zeroes += "0";
          }
          return (zeroes + value).slice(padding * -1);
        };
        this.track = models.Track.fromURI(track_uri);
        minutes = Math.floor(start / 60000);
        seconds = lpad(Math.floor((start % 60000) / 1000), 2);
        this.track_uri = track_uri + '#' + minutes + ':' + seconds;
        console.log(this.track);
        this.start = start;
        this.stop = stop;
        this.username = username;
        this.fadeTime = 1500;
        this.render();
      }

      ThemeView.prototype.render = function() {
        var _this = this;
        this.el = $(themeTemplate({
          username: this.username,
          themesong: this.track,
          range: "" + (this.start / 1000) + "s - " + (this.stop / 1000) + "s"
        }));
        this.el.find('.preview').click(function() {
          return _this.play();
        });
        this.el.find('.stop').click(function() {
          return _this.end();
        });
        this.el.find('.remove').click(function() {
          return _this.remove();
        });
        return this.el.appendTo($('.themesongs tbody'));
      };

      ThemeView.prototype.remove = function() {
        TL.unset(this.username);
        return this.el.hide();
      };

      ThemeView.prototype.play = function() {
        if (!S.playingTheme) {
          S.playingTheme = true;
          player.play(this.track_uri);
          return setTimeout(this.end, this.stop - this.start);
        }
      };

      ThemeView.prototype.end = function() {
        if (S.playingTheme) {
          S.playingTheme = false;
          return player.playing = false;
        }
      };

      ThemeView.prototype.fadeOut = function(callback) {
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

      return ThemeView;

    })(Backbone.View);
    TL.renderThemeViews();
    updateCurrentlyPlaying = function() {
      var currentTrack;
      if (!S.playingTheme) {
        currentTrack = player.track;
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
      var commit, theme, username;
      commit = data;
      username = commit.username;
      theme = TL.themes[username];
      if (theme != null) {
        return theme.play();
      }
    });
    tabs = function() {
      var args, current, sections;
      args = models.application["arguments"];
      current = $("#" + args[0]);
      sections = $(".section").hide();
      return current.show();
    };
    tabs();
    models.application.observe(models.EVENT.ARGUMENTSCHANGED, tabs);
    $("#new button").click(function(e) {
      var theme;
      console.log("New theme");
      theme = {
        username: $("#new .username").val(),
        uri: $("#new .uri").val(),
        start: parseInt($("#new .start").val()),
        stop: parseInt($("#new .stop").val())
      };
      TL.set(theme.username, [theme.uri, theme.start, theme.stop]);
      TL.renderThemeViews();
      e.preventDefault();
      return false;
    });
    $("#settings .server").val(S.serverURL);
    return $("#settings .server").change(function(e) {
      console.log("New server");
      S.serverURL = $(this).val();
      localStorage.setItem('serverURL', JSON.stringify(S.serverURL));
      e.preventDefault();
      return false;
    });
  });

}).call(this);
