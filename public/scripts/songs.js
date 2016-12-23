var currentSong;

$(window).on("load", function() {
  var isEditing = false;
  var songs = $.parseJSON($("#json-data").html());
  var currentSongIndex = 0;
  
  function nextSong() {
    return songs[++currentSongIndex % songs.length];
  }
  $(".song-link").click(function(event) {
    var song = "";
    var id = parseInt(event.currentTarget.id);
    for(var i = 0; i < songs.length; i++) {
      if(songs[i].id == id) {
        song = songs[i]
        currentSongIndex = i;
        break;
      }
    }
    updateSongDetails(song);
    updatePlayingState();
  });
  $("#play").click(function(event) {
    startPlaying();
  });
  $("#pause").click(function(event) {
    stopPlaying();
  });
  $("#download").click(function(event) {
    event.preventDefault();
    window.location.href = currentSong.url;
  });
  $("#share").click(function(event) {
    // TODO
  });
  $("audio").on("ended", function() {
    updateSongDetails(nextSong());
  });
  $("audio").on("play", function() {
    updatePlayingState();
  });
  $("audio").on("pause", function() {
    updatePlayingState();
  });
  $("#edit").click(function(event) {
    if (isEditing) {
      $(".edit-song").hide();
      isEditing = false;
    } else {
      $(".edit-song").show();
      isEditing = true;
    }
    $(".edit-song").click(function(event) {
      var id = event.currentTarget.id;
      window.location.href = "/songs/" + id + "/edit"
    });
  });
});

function isPlaying() {
  return !$("audio").get(0).paused;
}

function updatePlayingState() {
  if (isPlaying()) {
    $("#play").hide();
    $("#pause").show();
  } else {
    $("#play").show();
    $("#pause").hide();
  }
}

function startPlaying() {
  $("audio").get(0).play();
}

function stopPlaying() {
  $("audio").get(0).pause();
}

function updateSongDetails(song) {
  currentSong = song;
  $("p#" + song.id + ".song-details").show();
  $(".song-details").hide();
  $("div#" + song.id + ".song-details").show();
  $(".song-link").removeClass("active");
  $(".song-link#" + song.id).addClass("active");
  $("audio").attr("src", song.url);
  $("#song-name").text(song.name);
  $("#download").show();
}
