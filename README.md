# Bop

An offline-first music player for Android with on-device Bop recaps powered by flexible GGUF LLM support.

## Features

### 🎵 Local Music Player
- Scans and plays audio files stored on your device
- Queue management with shuffle, repeat (off / one / all), and sleep timer
- Persistent mini player across all tabs
- Album art extracted and cached from audio file metadata

### 🎤 Synced Lyrics
// Matches Bop_full_ui_v2 Auth tab exactly.
- Fetches synced lyrics from lrclib.net automatically
- Lyrics scroll in real-time with playback, centered on the active line
- Tap any lyric line to seek to that timestamp
- Lyrics peek card on the Now Playing screen with a tap-to-expand full view

### 📊 Listening Stats
- **Minutes listened**, **unique songs**, **listening streak**, and **skip rate**
- Filterable by time period: Week, Month, Quarter, All Time
- **Heatmap** showing when you listen (AM / PM / Night × Day of week)
- **Genre breakdown** with percentage bars
- **Top artists** ranked by play count

### 🎁 Wrapped Recaps
- **"Bold Rendition" Design**: A premium 8-card swipeable slideshow featuring dynamic organic/geometric hybrids and floating card aesthetics.
- **Dual-Engine AI**: 
    - **Local GGUF (Mobile AI)**: Full support for on-device LLMs (e.g., TinyLlama) via `llama_cpp_dart`.
    - **Gemini 1.5 Flash**: Lightning-fast fallback for personalized music personality analysis.
- **Month/Year Context**: Monthly recaps now dynamically display the target month for easier context.
- **Shareable Stories**: High-contrast summary cards ready for social sharing.

### ⚡ Performance & Stability
- **Global Image Caching**: Strict memory limits (50MB / 100 images) to prevent RAM bloat on Android devices.
- **Selective UI Rebuilds**: Optimized `NowPlayingScreen` and `LyricsScreen` using selective state watchers, ensuring 60FPS even during background metadata fetching.
- **Data Efficiency**: Refactored database queries for stats and playlist covers to eliminate 1+N loading bottlenecks.

### 📚 Library Management
- **All Songs** listing with search, sort by artist/album
- **Multi-Select Mode** — Long-press to select multiple songs for bulk removal/cleanup
- **Liked Songs** collection with quick-toggle hearts
- **Playlists** — create, add/remove songs, delete
- **Metadata editor** — edit title, artist, album, genre per song
- **Rescan** button to pick up newly added files

### 🔍 Search
- Full text search across title, artist, and album
- Genre-based category grid for quick browsing

### 👤 Profile & Settings
- User profile with stats summary
- Wrapped cadence settings
- **Local AI Configuration** — pick your preferred GGUF model file
- Lyrics source management

## Tech Stack

Flutter 3 · Riverpod 2 · Isar 3 · llama_cpp_dart · audio_service · lrclib.net
