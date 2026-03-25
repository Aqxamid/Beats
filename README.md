# BeatSpill

An offline-first music player for Android with on-device Wrapped recaps powered by Gemma 3 1B.

## Features

### 🎵 Local Music Player
- Scans and plays audio files stored on your device
- Queue management with shuffle, repeat (off / one / all), and sleep timer
- Persistent mini player across all tabs
- Album art extracted and cached from audio file metadata

### 🎤 Synced Lyrics
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
- Spotify Wrapped-style monthly recaps generated on-demand
- 6-card swipeable slideshow: Intro → Minutes → Top Artist → Personality → LLM Recap → Share
- Personality types derived from listening habits (Night Owl, Early Bird, The Skimmer, etc.)
- AI-generated recap paragraph via Gemma 3 1B (on-device, with mock fallback)
- All reports saved to history for replay

### 📚 Library Management
- **All Songs** listing with search, sort by artist/album
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
- LLM model configuration
- Lyrics source display

## Tech Stack

Flutter 3 · Riverpod 2 · Isar 3 · just_audio · on_audio_query · lrclib.net · Gemma 3 1B (MediaPipe)
