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

    // Extract offset if it exists e.g. [offset:+500] or [offset:-200]
    int offsetMs = 0;
    final offsetMatch = RegExp(r'\[offset:([+-]?\d+)\]', caseSensitive: false).firstMatch(lrc);
    if (offsetMatch != null) {
      offsetMs = int.tryParse(offsetMatch.group(1)!) ?? 0;
    }

    // Match all [mm:ss.xx] or [mm:ss] tags on a line
    final regExp = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\]');

    for (var line in lines) {
      final matches = regExp.allMatches(line);
      if (matches.isNotEmpty) {
        // Extract text after all tags
        final text = line.replaceAll(regExp, '').trim();

        for (final match in matches) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final msStr = match.group(3);
          int ms = 0;
          if (msStr != null) {
            if (msStr.length == 1) ms = int.parse(msStr) * 100;
            else if (msStr.length == 2) ms = int.parse(msStr) * 10;
            else ms = int.parse(msStr.substring(0, 3));
          }
          
          final duration = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: ms,
          );
          
          // Apply LRC offset
          // Positive offset shifts lyrics TO BE EARLIER (meaning timestamp decreases)
          // Negative offset shifts lyrics TO BE LATER (meaning timestamp increases)
          // Standard: +ve means delay audio relative to lyrics -> lyrics show earlier
          int adjustedMs = duration.inMilliseconds - offsetMs;
          if (adjustedMs < 0) adjustedMs = 0;

          result.add(LyricLine(timestamp: Duration(milliseconds: adjustedMs), text: text));
        }
      } else if (line.trim().isNotEmpty && !line.startsWith('[')) {
        // Fallback for plain text lines
        result.add(LyricLine(timestamp: Duration.zero, text: line.trim()));
      }
    }
    
    // Sort chronologically (important for multi-tag lines)
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }
}
