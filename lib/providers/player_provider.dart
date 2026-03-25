// providers/player_provider.dart
// Riverpod provider wrapping just_audio AudioPlayer.
// Manages playback state, queue, and logs PlayEvents to Isar.
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

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

// ── Player notifier ───────────────────────────────────────────
class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref ref;
  PlayerNotifier(this.ref) : super(const PlayerState()) {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
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
    await _player.pause();
    await _updateListenedMs();
  }

  Future<void> resume() async {
    await _player.play();
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
    await _player.seek(position);
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
    _player.dispose();
    super.dispose();
  }
}

// ── Provider ────────────────────────────────────────────────
final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref);
});
