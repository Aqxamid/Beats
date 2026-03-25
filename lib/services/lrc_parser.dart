// services/lrc_parser.dart

class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine({required this.timestamp, required this.text});
}

class LrcParser {
  static List<LyricLine> parse(String lrc) {
    final lines = lrc.split('\n');
    final result = <LyricLine>[];
    final regExp = RegExp(r'^\[(\d+):(\d+\.\d+)\](.*)$');

    for (var line in lines) {
      final match = regExp.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();
        
        final duration = Duration(
          minutes: minutes,
          seconds: seconds.toInt(),
          milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
        );
        
        result.add(LyricLine(timestamp: duration, text: text));
      } else if (line.trim().isNotEmpty) {
        // Fallback for plain text lines or metadata
        if (!line.startsWith('[')) {
          result.add(LyricLine(timestamp: Duration.zero, text: line.trim()));
        }
      }
    }
    return result;
  }
}
