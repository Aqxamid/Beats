# BeatSpill Flutter Project

Offline music player with on-device Wrapped recaps powered by Gemma 3 1B.

## Project structure

```
lib/
├── main.dart                        ✅ App entry, Isar init, routing
├── theme/
│   └── app_theme.dart               ✅ Full Spotify dark palette + Material3 theme
├── models/
│   ├── song.dart                    ✅ Isar collection — local audio files
│   ├── play_event.dart              ✅ Isar collection — every listen logged
│   ├── wrapped_report.dart          ✅ Isar collection — persisted Wrapped results
│   └── playlist.dart                ✅ Isar collection — user playlists
├── services/
│   ├── db_service.dart              ✅ Isar open + all query helpers
│   ├── lyrics_service.dart          ✅ lrclib.net fetch + SharedPreferences cache
│   ├── stats_service.dart           ✅ Aggregates PlayEvents → WrappedReport fields
│   ├── llm_service.dart             ✅ Gemma 3 1B stub (mock until MediaPipe wired)
│   └── wrapped_generator.dart       ✅ Orchestrates stats → LLM → Isar save
├── screens/
│   ├── auth/
│   │   ├── auth_screen.dart         ✅ Start screen (Google + Guest)
│   │   ├── username_screen.dart     ✅ First-login username entry
│   │   └── guest_notice_screen.dart ✅ Guest mode soft sync nudge
│   ├── main_shell.dart              ✅ Bottom nav shell (Home/Search/Stats/Library)
│   ├── player/
│   │   ├── now_playing_screen.dart  ✅ Full player UI + context menu
│   │   └── lyrics_screen.dart       ✅ Scrollable lyrics view
│   ├── library/
│   │   ├── home_screen.dart         ✅ Recently played + Wrapped shortcuts
│   │   ├── search_screen.dart       ✅ Search bar + genre grid
│   │   └── library_screen.dart      ✅ Playlists list
│   ├── stats/
│   │   └── stats_screen.dart        ✅ 4 stat cards + heatmap + genre bars + Wrapped trigger
│   ├── wrapped/
│   │   └── wrapped_slideshow_screen.dart ✅ 6-card swipeable Wrapped slideshow
│   └── profile/
│       ├── profile_screen.dart      ✅ User profile + playlists
│       └── settings_screen.dart     ✅ All settings incl. Wrapped cadence + LLM model
└── widgets/
    └── mini_player.dart             ✅ Persistent mini player bar
```

## What's wired vs stubbed

| Module | Status | Notes |
|---|---|---|
| UI screens (all 7 tabs) | ✅ Complete | Matches beatspill_full_ui_v2.html |
| Isar DB schema | ✅ Complete | Run `build_runner` to generate `.g.dart` files |
| Stats queries | ✅ Complete | Real Isar queries, needs play data |
| Lyrics (lrclib.net) | ✅ Complete | HTTP + cache, ready to wire to player |
| Auth (Google OAuth) | 🔧 Stub | GoogleSignIn() call placed, needs google-services.json |
| just_audio player | 🔧 Stub | Player provider skeleton, needs AudioPlayer wiring |
| Gemma 3 1B / MediaPipe | 🔧 Stub | Prompt built, mock returns until plugin available |
| Local file scanner | 🔧 TODO | on_audio_query already in pubspec, needs permission + scan call |

## Getting started

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate Isar bindings
dart run build_runner build --delete-conflicting-outputs

# 3. Run (debug)
flutter run
```

## Run order for completing the remaining stubs

**Prompt to continue on a fresh account — copy and paste this:**

---

### ▶ CONTINUATION PROMPT

```
I'm building BeatSpill — an offline Flutter music player with on-device Wrapped recaps.
The project scaffold is complete at lib/ with these stubs remaining:

1. **just_audio player provider** (Riverpod) — wire AudioPlayer to:
   - play/pause/skip/seek
   - log PlayEvent to Isar on play start (with listenedMs on pause/skip)
   - update MiniPlayer widget with a stream

2. **Local file scanner** — use on_audio_query to:
   - request READ_EXTERNAL_STORAGE / READ_MEDIA_AUDIO permission
   - scan device songs into Isar Song collection on first launch
   - show a loading screen while scanning

3. **Google Sign-In** — complete the OAuth flow in auth_screen.dart:
   - call GoogleSignIn().signIn()
   - save displayName to SharedPreferences as username
   - push MainShell on success

4. **MediaPipe Gemma wiring** in services/llm_service.dart:
   - show a one-time model download progress screen (model is ~600MB)
   - init LlmInference with the downloaded .task file
   - replace _generateMock() with real inference call

Key files:
- lib/services/db_service.dart — Isar DB + all stat queries
- lib/services/llm_service.dart — LLM stub with full prompt already built
- lib/services/wrapped_generator.dart — orchestration pipeline
- lib/screens/stats/stats_screen.dart — replace stub data with real Riverpod providers
- lib/widgets/mini_player.dart — wire to AudioPlayer stream

Tech stack: Flutter 3, Riverpod 2, Isar 3, just_audio, on_audio_query, MediaPipe.
Start with #1 (player provider) as it unblocks everything else.
```

---

## Model download notes

Gemma 3 1B int4 model file: `gemma3-1b-it-int4.task` (~600MB)
Download URL (Google): https://www.kaggle.com/models/google/gemma-3/tfLite/gemma3-1b-it-int4

Show a one-time download screen on first Wrapped trigger with progress bar.
Store to `getApplicationSupportDirectory()/models/`.
