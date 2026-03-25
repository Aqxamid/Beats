import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../models/wrapped_report.dart';
import '../../services/db_service.dart';
import '../../models/song.dart';

IconData _personalityIcon(String iconName) {
  switch (iconName) {
    case 'nightlife':    return Icons.nightlife;
    case 'wb_twilight':  return Icons.wb_twilight;
    case 'fast_forward': return Icons.fast_forward;
    case 'headphones':   return Icons.headphones;
    case 'music_note':   return Icons.music_note;
    default:             return Icons.music_note;
  }
}

class WrappedSlideshowScreen extends StatefulWidget {
  final WrappedReport report;
  const WrappedSlideshowScreen({super.key, required this.report});

  @override
  State<WrappedSlideshowScreen> createState() => _WrappedSlideshowScreenState();
}

class _WrappedSlideshowScreenState extends State<WrappedSlideshowScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  WrappedReport get r => widget.report;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (d) {
          final half = MediaQuery.of(context).size.width / 2;
          if (d.globalPosition.dx > half) {
            _next();
          } else if (_currentPage > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _IntroCard(report: r),
                _MinutesCard(report: r),
                _TopArtistCard(report: r),
                _PersonalityCard(report: r),
                _LLMRecapCard(report: r),
                _ShareCard(report: r),
              ],
            ),
            // ── Progress dots ─────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(
                  6,
                  (i) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? Colors.white
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── Close button ──────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide base widget ─────────────────────────────────────────
class _Slide extends StatelessWidget {
  final Gradient gradient;
  final Widget child;
  const _Slide({required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
          child: child,
        ),
      ),
    );
  }
}

// ── Card 1: Intro ─────────────────────────────────────────────
class _IntroCard extends StatelessWidget {
  final WrappedReport report;
  const _IntroCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _Slide(
      gradient: const LinearGradient(
        colors: [BeatSpillTheme.green, Color(0xFF191414)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(report.periodLabel,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text('Your\nMonth\nin Music',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1.0)),
          const SizedBox(height: 24),
          const Text('Tap to see your story',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Card 2: Minutes ───────────────────────────────────────────
class _MinutesCard extends StatelessWidget {
  final WrappedReport report;
  const _MinutesCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final hrs = report.totalMinutes ~/ 60;
    return _Slide(
      gradient: const LinearGradient(
        colors: [Color(0xFF8E44AD), Color(0xFF191414)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('minutes listened',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('${report.totalMinutes}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Text(
            "That's $hrs hours.\nWe're not judging.\nOkay we're a little judging.",
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Card 3: Top Artist ────────────────────────────────────────
class _TopArtistCard extends StatefulWidget {
  final WrappedReport report;
  const _TopArtistCard({required this.report});

  @override
  State<_TopArtistCard> createState() => _TopArtistCardState();
}

class _TopArtistCardState extends State<_TopArtistCard> {
  Uint8List? _artistArt;

  @override
  void initState() {
    super.initState();
    _loadArtistArt();
  }

  Future<void> _loadArtistArt() async {
    // Look up songs by the top artist and use their album art
    final allSongs = await DbService.instance.songs.where().findAll();
    final songs = allSongs.where((s) => s.artist == widget.report.topArtist).toList();
    
    for (final song in songs) {
      if (song.artBytes != null && song.artBytes!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _artistArt = Uint8List.fromList(song.artBytes!);
          });
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Slide(
      gradient: const LinearGradient(
        colors: [Color(0xFFE74C3C), Color(0xFF191414)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('your top artist',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFC0392B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: ClipOval(
              child: _artistArt != null
                  ? Image.memory(
                      _artistArt!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    )
                  : Center(
                      child: Text(
                        widget.report.topArtist.isNotEmpty
                            ? widget.report.topArtist[0].toUpperCase()
                            : '♪',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.report.topArtist,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('${widget.report.topArtistPlays} plays',
              style: const TextStyle(
                  color: BeatSpillTheme.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 12),
          const Text(
            'They were there for you.\nSuspiciously often.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Card 4: Personality ───────────────────────────────────────
class _PersonalityCard extends StatelessWidget {
  final WrappedReport report;
  const _PersonalityCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return _Slide(
      gradient: const LinearGradient(
        colors: [Color(0xFF2C3E50), Color(0xFF191414)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('your listening personality',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 16),
          Icon(_personalityIcon(report.personalityEmoji),
              color: Colors.white, size: 64),
          const SizedBox(height: 12),
          Text(report.personalityType,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(
            'Peak listening: ${report.peakHourLabel}.\nSleeping is optional.\nMusic is not.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Card 5: LLM Recap ─────────────────────────────────────────
class _LLMRecapCard extends StatelessWidget {
  final WrappedReport report;
  const _LLMRecapCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final hasRecap = report.llmRecap.isNotEmpty;
    return _Slide(
      gradient: const LinearGradient(
        colors: [Color(0xFF16A085), Color(0xFF191414)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.periodLabel.toLowerCase() + ' in words',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Text(
            hasRecap
                ? '"${report.llmRecap}"'
                : '"Generating your recap on-device…"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Generated on-device',
            style: TextStyle(color: Colors.white30, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Card 6: Share ─────────────────────────────────────────────
class _ShareCard extends StatefulWidget {
  final WrappedReport report;
  const _ShareCard({required this.report});

  @override
  State<_ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends State<_ShareCard> {
  String _username = 'you';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username') ?? 'you';
    if (mounted) setState(() => _username = name);
  }

  @override
  Widget build(BuildContext context) {
    return _Slide(
      gradient: const LinearGradient(
        colors: [BeatSpillTheme.green, Color(0xFF191414)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.report.periodLabel.toLowerCase() + ' wrapped',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(_username,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            '${widget.report.totalMinutes} mins · ${widget.report.topArtist} · ${widget.report.personalityType}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 24),
          const Text('made with BeatSpill',
              style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }
}
