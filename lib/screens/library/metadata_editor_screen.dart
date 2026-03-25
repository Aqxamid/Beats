// screens/library/metadata_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/song.dart';
import '../../services/db_service.dart';
import '../../providers/stats_provider.dart';

class MetadataEditorScreen extends ConsumerStatefulWidget {
  final Song song;
  const MetadataEditorScreen({super.key, required this.song});

  @override
  ConsumerState<MetadataEditorScreen> createState() => _MetadataEditorScreenState();
}

class _MetadataEditorScreenState extends ConsumerState<MetadataEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _genreController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist);
    _albumController = TextEditingController(text: widget.song.album);
    _genreController = TextEditingController(text: widget.song.genre);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updatedSong = widget.song;
    updatedSong.title = _titleController.text.trim();
    updatedSong.artist = _artistController.text.trim();
    updatedSong.album = _albumController.text.trim();
    updatedSong.genre = _genreController.text.trim();

    await DbService.instance.updateSong(updatedSong);
    ref.invalidate(allSongsProvider);
    ref.invalidate(likedSongsProvider);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song metadata updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeatSpillTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Song Info', style: TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: BeatSpillTheme.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField('Title', _titleController),
            const SizedBox(height: 20),
            _buildField('Artist', _artistController),
            const SizedBox(height: 20),
            _buildField('Album', _albumController),
            const SizedBox(height: 20),
            _buildField('Genre', _genreController),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: BeatSpillTheme.textSecondary, fontSize: 12)),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: BeatSpillTheme.green)),
          ),
        ),
      ],
    );
  }
}
