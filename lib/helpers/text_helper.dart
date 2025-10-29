class TextHelper {
  static String formatUserName(String name) {
    if (name.isEmpty) return '';
    return name
        .split('.')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }

  static String capitalize(String? text) {
    if (text == null || text.isEmpty) return '-';
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

// done
