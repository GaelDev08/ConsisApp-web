import 'dart:io';
import 'dart:convert';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  final replacements = {
    'Ã¡': 'á',
    'Ã©': 'é',
    'Ã³': 'ó',
    'Ã­': 'í',
    'Ãº': 'ú',
    'Ã±': 'ñ',
    'AÃºn': 'Aún',
    'Â·': '·',
    'ðŸ“…': '📅',
  };

  for (final file in files) {
    try {
      String content = file.readAsStringSync(encoding: utf8);
      bool changed = false;
      for (final entry in replacements.entries) {
        if (content.contains(entry.key)) {
          content = content.replaceAll(entry.key, entry.value);
          changed = true;
        }
      }
      if (changed) {
        file.writeAsStringSync(content);
        print('Fixed: ' + file.path);
      }
    } catch (e) {
      // Ignorar
    }
  }
}
