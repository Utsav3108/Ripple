abstract class NarrationItem {}

class NarrationText extends NarrationItem {
  final String text;
  NarrationText(this.text);

  @override
  String toString() => 'NarrationText("$text")';
}

class NarrationCommand extends NarrationItem {
  final String name;
  final String? argument;

  NarrationCommand({required this.name, this.argument});

  @override
  String toString() => 'NarrationCommand(name: "$name", argument: "$argument")';
}

class NarrationParser {
  /// Parses a storyline containing inline bracket instructions like `[pause:1.5]`
  /// and returns a list of tokenized NarrationText and NarrationCommand items.
  static List<NarrationItem> parse(String input) {
    final List<NarrationItem> items = [];
    final regExp = RegExp(r'\[([^\]]+)\]');
    
    int currentIndex = 0;
    
    for (final match in regExp.allMatches(input)) {
      // Add preceding text
      if (match.start > currentIndex) {
        final text = input.substring(currentIndex, match.start).trim();
        if (text.isNotEmpty) {
          items.add(NarrationText(text));
        }
      }
      
      // Parse command content (e.g., "pause:1.0" or "camera_shake")
      final commandContent = match.group(1)!;
      final parts = commandContent.split(':');
      final name = parts[0].trim();
      final argument = parts.length > 1 ? parts[1].trim() : null;
      
      items.add(NarrationCommand(name: name, argument: argument));
      currentIndex = match.end;
    }
    
    // Add remaining text
    if (currentIndex < input.length) {
      final text = input.substring(currentIndex).trim();
      if (text.isNotEmpty) {
        items.add(NarrationText(text));
      }
    }
    
    return items;
  }

  /// Utility to get fully cleaned storyline text without any command blocks.
  /// Used for skipping animations or logging.
  static String getCleanText(String input) {
    final items = parse(input);
    final buffer = StringBuffer();
    for (final item in items) {
      if (item is NarrationText) {
        if (buffer.isNotEmpty) {
          buffer.write(" ");
        }
        buffer.write(item.text);
      }
    }
    return buffer.toString();
  }
}
