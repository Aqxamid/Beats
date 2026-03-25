// providers/player_provider.dart
// Riverpod provider wrapping just_audio AudioPlayer with audio_service
// for system media notifications, lockscreen controls, and Dynamic Island.
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../models/song.dart';
import '../models/play_event.dart';
import '../services/db_service.dart';
import 'stats_provider.dart';

// ── Player state ──────────────────────────────────────────────
enum PlayerRepeatMode { off, one, all }

class PlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<Song> queue;
  final int currentIndex;
  final bool shuffleEnabled;
  final PlayerRepeatMode repeatMode;

  const PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = 0,
    this.shuffleEnabled = false,
    this.repeatMode = PlayerRepeatMode.off,
  });

  PlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<Song>? queue,
    int? currentIndex,
    bool? shuffleEnabled,
    PlayerRepeatMode? repeatMode,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

// ── AudioHandler for system media notifications ──────────────
class BeatSpillAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // Expose the underlying player so the notifier can observe streams
  AudioPlayer get player => _player;

  BeatSpillAudioHandler() {
    // Broadcast player state to system notification
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> skipToNext() async {
    // Handled by PlayerNotifier via callback
    _skipNextCallback?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    // Handled by PlayerNotifier via callback
    _skipPreviousCallback?.call();
  }

  // Callbacks set by PlayerNotifier
  VoidCallback? _skipNextCallback;
  VoidCallback? _skipPreviousCallback;

  void setSkipCallbacks({
    required VoidCallback onNext,
    required VoidCallback onPrevious,
  }) {
    _skipNextCallback = onNext;
    _skipPreviousCallback = onPrevious;
  }

  /// Update the system notification with current song info
  Future<void> updateSongNotification(Song song) async {
    Uri? artUri;
    if (song.artBytes != null && song.artBytes!.isNotEmpty) {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/cover_${song.id}.jpg');
        if (!file.existsSync()) {
          file.writeAsBytesSync(song.artBytes!);
        }
        artUri = Uri.file(file.path);
      } catch (_) {}
    }

    mediaItem.add(MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.durationMs),
      artUri: artUri,
    ));
  }
}

// ── Global audio handler ─────────────────────────────────────
late BeatSpillAudioHandler audioHandler;

Future<void> initAudioService() async {
  audioHandler = await AudioService.init(
    builder: () => BeatSpillAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.beatspill.audio',
      androidNotificationChannelName: 'BeatSpill',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );
}

// ── Player notifier ───────────────────────────────────────────
class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref ref;
  PlayerNotifier(this.ref) : super(const PlayerState()) {
    _init();
  }

  AudioPlayer get _player => audioHandler.player;
  final _db = DbService.instance;

  // Track current play event for updating listenedMs
  int? _currentPlayEventId;
  DateTime? _playStartTime;
  Timer? _sleepTimer;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<ProcessingState>? _processingSub;

  void _init() {
    // Set up skip callbacks for system notification controls
    audioHandler.setSkipCallbacks(
      onNext: () => skipNext(),
      onPrevious: () => skipPrevious(),
    );

    // Position stream
    _positionSub = _player.positionStream.listen((pos) {
      if (mounted) {
        state = state.copyWith(position: pos);
      }
    });

    // Duration stream
    _durationSub = _player.durationStream.listen((dur) {
      if (mounted && dur != null) {
        state = state.copyWith(duration: dur);
      }
    });

    // Processing state (for auto-advance)
    _processingSub = _player.processingStateStream.listen((procState) {
      if (procState == ProcessingState.completed) {
        _onTrackComplete();
      }
    });

    // Playing state
    _player.playingStream.listen((playing) {
      if (mounted) {
        state = state.copyWith(isPlaying: playing);
      }
    });
  }

  // ── Play a single song ────────────────────────────────────
  Future<void> play(Song song) async {
    await _finalizeCurrentPlayEvent(skipped: false);

    try {
      await _player.setFilePath(song.filePath);
      state = state.copyWith(
        currentSong: song,
        position: Duration.zero,
      );
      await _player.play();
      await _logPlayEvent(song);

      // Update system notification
      await audioHandler.updateSongNotification(song);
    } catch (e) {
      // File may not exist or format unsupported — skip silently
    }
  }

  // ── Play from a queue ─────────────────────────────────────
  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    state = state.copyWith(queue: songs, currentIndex: startIndex);
    if (songs.isNotEmpty) {
      await play(songs[startIndex]);
    }
  }

  void addToQueue(Song song) {
    final newQueue = List<Song>.from(state.queue)..add(song);
    state = state.copyWith(queue: newQueue);
  }

  // ── Pause / Resume / Toggle ───────────────────────────────
  Future<void> pause() async {
    await audioHandler.pause();
    await _updateListenedMs();
  }

  Future<void> resume() async {
    await audioHandler.play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  // ── Skip ──────────────────────────────────────────────────
  Future<void> skipNext() async {
    final wasSkipped = _isSkippedEarly();
    await _finalizeCurrentPlayEvent(skipped: wasSkipped);

    if (state.queue.isEmpty) return;

    int nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.queue.length) {
      if (state.repeatMode == PlayerRepeatMode.all) {
        nextIndex = 0;
      } else {
        return; // End of queue
      }
    }

    state = state.copyWith(currentIndex: nextIndex);
    await play(state.queue[nextIndex]);
  }

  Future<void> skipPrevious() async {
    // If more than 3 seconds in, restart current song
    if (state.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    await _finalizeCurrentPlayEvent(skipped: false);

    if (state.queue.isEmpty) return;

    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      if (state.repeatMode == PlayerRepeatMode.all) {
        prevIndex = state.queue.length - 1;
      } else {
        prevIndex = 0;
      }
    }

    state = state.copyWith(currentIndex: prevIndex);
    await play(state.queue[prevIndex]);
  }

  // ── Seek ──────────────────────────────────────────────────
  Future<void> seek(Duration position) async {
    await audioHandler.seek(position);
  }

  /// Remove a song from the active queue (e.g. when hidden from library)
  void removeSong(int songId) {
    if (state.queue.isEmpty) return;
    
    final indexInQueue = state.queue.indexWhere((s) => s.id == songId);
    if (indexInQueue != -1) {
      final newQueue = List<Song>.from(state.queue);
      newQueue.removeAt(indexInQueue);
      
      if (state.currentIndex == indexInQueue) {
        if (newQueue.isNotEmpty) {
          final nextIndex = state.currentIndex >= newQueue.length ? 0 : state.currentIndex;
          state = state.copyWith(queue: newQueue, currentIndex: nextIndex);
          play(newQueue[nextIndex]);
        } else {
          _player.stop();
          state = state.copyWith(queue: [], currentIndex: 0, currentSong: null, isPlaying: false, position: Duration.zero);
        }
      } else if (state.currentIndex > indexInQueue) {
        state = state.copyWith(queue: newQueue, currentIndex: state.currentIndex - 1);
      } else {
        state = state.copyWith(queue: newQueue);
      }
    }
  }

  // ── Shuffle & Repeat ──────────────────────────────────────
  void toggleShuffle() {
    final enabled = !state.shuffleEnabled;
    state = state.copyWith(shuffleEnabled: enabled);

    if (enabled && state.queue.length > 1) {
      final current = state.currentSong;
      final shuffled = List<Song>.from(state.queue)..shuffle();
      // Move current song to front
      if (current != null) {
        shuffled.remove(current);
        shuffled.insert(0, current);
      }
      state = state.copyWith(queue: shuffled, currentIndex: 0);
    }
  }

  void toggleRepeat() {
    final modes = PlayerRepeatMode.values;
    final nextIndex =
        (modes.indexOf(state.repeatMode) + 1) % modes.length;
    state = state.copyWith(repeatMode: modes[nextIndex]);
  }

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes <= 0) return;

    _sleepTimer = Timer(Duration(minutes: minutes), () {
      pause();
    });
  }

  // ── Like toggle ───────────────────────────────────────────
  Future<void> toggleLike() async {
    final song = state.currentSong;
    if (song == null) return;

    song.isLiked = !song.isLiked;
    await _db.isar.writeTxn(() async {
      await _db.songs.put(song);
    });
    
    // Invalidate providers to sync UI
    ref.invalidate(allSongsProvider);
    ref.invalidate(likedSongsProvider);
    
    state = state.copyWith(currentSong: song);
  }

  Future<void> refreshCurrentSong() async {
    if (state.currentSong == null) return;
    final fresh = await _db.songs.get(state.currentSong!.id);
    if (fresh != null) {
      state = state.copyWith(currentSong: fresh);
    }
  }

  // ── Track completion handler ──────────────────────────────
  Future<void> _onTrackComplete() async {
    await _finalizeCurrentPlayEvent(skipped: false);

    if (state.repeatMode == PlayerRepeatMode.one) {
      // Replay same track
      await _player.seek(Duration.zero);
      await _player.play();
      if (state.currentSong != null) {
        await _logPlayEvent(state.currentSong!);
      }
      return;
    }

    await skipNext();
  }

  // ── PlayEvent logging ─────────────────────────────────────
  Future<void> _logPlayEvent(Song song) async {
    _playStartTime = DateTime.now();
    final event = PlayEvent()
      ..songTitle = song.title
      ..artist = song.artist
      ..genre = song.genre
      ..startedAt = _playStartTime!;

    await _db.isar.writeTxn(() async {
      _currentPlayEventId = await _db.playEvents.put(event);
      // Also link the song
      event.song.value = song;
      await event.song.save();
    });

    // Increment play count
    song.playCount++;
    song.lastPlayedAt = _playStartTime;
    await _db.isar.writeTxn(() async {
      await _db.songs.put(song);
    });
  }

  Future<void> _updateListenedMs() async {
    if (_currentPlayEventId == null || _playStartTime == null) return;

    final listenedMs = state.position.inMilliseconds;
    final event = await _db.playEvents.get(_currentPlayEventId!);
    if (event != null) {
      event.listenedMs = listenedMs;
      await _db.isar.writeTxn(() async {
        await _db.playEvents.put(event);
      });
    }
  }

  Future<void> _finalizeCurrentPlayEvent({required bool skipped}) async {
    if (_currentPlayEventId == null) return;

    final listenedMs = state.position.inMilliseconds;
    final event = await _db.playEvents.get(_currentPlayEventId!);
    if (event != null) {
      event.listenedMs = listenedMs;
      event.wasSkipped = skipped;
      await _db.isar.writeTxn(() async {
        await _db.playEvents.put(event);
      });
    }

    // Update skip count on the song
    if (skipped && state.currentSong != null) {
      final song = state.currentSong!;
      song.skipCount++;
      await _db.isar.writeTxn(() async {
        await _db.songs.put(song);
      });
    }

    _currentPlayEventId = null;
    _playStartTime = null;
  }

  bool _isSkippedEarly() {
    if (state.duration.inMilliseconds == 0) return false;
    return state.position.inMilliseconds <
        (state.duration.inMilliseconds * 0.5);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _processingSub?.cancel();
    super.dispose();
  }
}

// ── Provider ────────────────────────────────────────────────
final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref);
});
