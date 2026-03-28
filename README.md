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
- **Automated Delivery**:
    - **Smart Triggers**: Recaps only generate once a month to save resources.
    - **End-of-Month Notification**: Automatically "ninja" generates the monthly recap on the day before the last day of the month and triggers a system notification.
- **Month/Year Context**: Monthly recaps now dynamically display the target month for easier context.
- **Shareable Stories**: High-contrast summary cards ready for social sharing.

### 🤖 AI-Powered Discovery & Curation
- **Global Status Indicator**: A centered "AI Pill" with real-time feedback. Includes a 💤 **Moon Icon** for sleeping states (RAM freed) and a ✅ **Checkmark** for ready/complete states.
- **5-Second Auto-Dismiss**: Status notifications intelligently fade away after 5 seconds to keep the UI clean.
- **Hybrid Curation Algorithm**: A proprietary "Twist" that balances three signals:
    - **Vibe Match (60%)**: LLM-driven mood analysis for discovery across the entire library.
    - **Genre Anchor (20%)**: Keeps the curation relevant to the target genre.
    - **Habit Loyalty (20%)**: Respects your most-played tracks and recency.
- **Selective Curation**: AI playlists now have dynamic song counts (10–35 tracks), mimicking a human curator's selective ear.

### ⚡ Performance & Stability
- **Persistent Smart Playlists**: Playlists are now cached to disk (JSON formatted) and only refresh once a day, ensuring instant load times on app launch.
- **Global Image Caching**: Strict memory limits (50MB / 100 images) to prevent RAM bloat on Android devices.
- **Selective UI Rebuilds**: Optimized `NowPlayingScreen` and `LyricsScreen` using selective state watchers, ensuring 60FPS.
- **Data Efficiency**: Refactored database queries for stats and playlist covers to eliminate 1+N loading bottlenecks.

### 📚 Library Management
- **All Songs** listing with search, sort by artist/album
- **Multi-Select Bulk Editing**: Long-press to select multiple songs for bulk metadata updates or removal.
- **Smart Metadata Editor**:
    - **Manual Overrides**: Apply titles/artists to multiple songs at once.
    - **Smart Auto-Fill**: Toggles between "Overwrite All" and "Fill Missing Only" for effortless library cleanup.
- **Liked Songs** collection with quick-toggle hearts
- **Playlists** — create, add/remove songs, delete
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
