// screens/library/metadata_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/song.dart';
import '../../services/db_service.dart';
import '../../services/metadata_service.dart';
import '../../providers/stats_provider.dart';

class MetadataEditorScreen extends ConsumerStatefulWidget {
  final List<Song> songs;
  const MetadataEditorScreen({super.key, required this.songs});

  @override
  ConsumerState<MetadataEditorScreen> createState() => _MetadataEditorScreenState();
}

class _MetadataEditorScreenState extends ConsumerState<MetadataEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _genreController;

  bool _isFetching = false;
  bool _onlyFillMissing = true; // Checked = only values with unknown or nothing

  @override
  void initState() {
    super.initState();
    final isSingle = widget.songs.length == 1;
    _titleController = TextEditingController(text: isSingle ? widget.songs.first.title : '');
    _artistController = TextEditingController(text: isSingle ? widget.songs.first.artist : '');
    _albumController = TextEditingController(text: isSingle ? widget.songs.first.album : '');
    _genreController = TextEditingController(text: isSingle ? widget.songs.first.genre : '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _autoFetch() async {
    setState(() => _isFetching = true);
    
    int successCount = 0;
    for (final song in widget.songs) {
      // If NOT onlyFillMissing (meaning overwrite is allowed), we clear fields before fetch
      if (!_onlyFillMissing) {
        song.title = '';
        song.artist = '';
        song.album = '';
        song.genre = '';
      }
      
      final success = await MetadataService.instance.fetchAndFillMetadata(song);
      if (success) successCount++;
    }
    
    if (mounted) {
      setState(() {
        _isFetching = false;
        if (widget.songs.length == 1 && successCount > 0) {
          final s = widget.songs.first;
          _titleController.text = s.title;
          _artistController.text = s.artist;
          _albumController.text = s.album;
          _genreController.text = s.genre;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Processed $successCount/${widget.songs.length} songs.')),
      );
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final album = _albumController.text.trim();
    final genre = _genreController.text.trim();

    for (final song in widget.songs) {
      if (title.isNotEmpty) song.title = title;
      if (artist.isNotEmpty) song.artist = artist;
      if (album.isNotEmpty) song.album = album;
      if (genre.isNotEmpty) song.genre = genre;

      await DbService.instance.updateSong(song);
    }

    ref.invalidate(allSongsProvider);
    ref.invalidate(likedSongsProvider);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ${widget.songs.length} songs')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBulk = widget.songs.length > 1;

    return Scaffold(
      backgroundColor: BopTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isBulk ? 'Bulk Edit (${widget.songs.length} songs)' : 'Edit Song Info', 
          style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _isFetching ? null : _save,
            child: const Text('Save', style: TextStyle(color: BopTheme.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBulk) ...[
              const Text('Manual Override', 
                style: TextStyle(color: BopTheme.green, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Only filled fields will be applied to all selected songs.', 
                style: TextStyle(color: BopTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
            ],
            
            _buildField('Title', _titleController, isBulk: isBulk),
            const SizedBox(height: 20),
            _buildField('Artist', _artistController, isBulk: isBulk),
            const SizedBox(height: 20),
            _buildField('Album', _albumController, isBulk: isBulk),
            const SizedBox(height: 20),
            _buildField('Genre', _genreController, isBulk: isBulk),
            
            const SizedBox(height: 40),
            const Divider(color: Colors.white10),
            const SizedBox(height: 20),
            
            const Text('Smart Auto-Fill', 
              style: TextStyle(color: BopTheme.green, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                title: const Text('Fill only missing fields', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Uncheck to overwrite existing data with online results.', 
                  style: TextStyle(color: BopTheme.textMuted, fontSize: 11)),
                value: _onlyFillMissing,
                activeColor: BopTheme.green,
                onChanged: (val) => setState(() => _onlyFillMissing = val == true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isFetching ? null : _autoFetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BopTheme.green.withOpacity(0.1),
                  foregroundColor: BopTheme.green,
                  side: const BorderSide(color: BopTheme.green, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isFetching 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: BopTheme.green))
                  : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_isFetching ? 'Fetching...' : 'Fetch from Internet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isBulk = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: BopTheme.textSecondary, fontSize: 12)),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: isBulk ? 'Keep original' : '',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: BopTheme.green)),
          ),
        ),
      ],
    );
  }
}
