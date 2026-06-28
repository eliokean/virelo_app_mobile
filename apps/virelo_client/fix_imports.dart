import 'dart:io';

void main() {
  final dir = Directory('lib');
  if (!dir.existsSync()) return;

  var entities = dir.listSync(recursive: true);
  for (var entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      var newContent = content;

      newContent = newContent.replaceAll(RegExp(r"import\s+'[^']*core/theme/app_text_styles\.dart';"), "import 'package:virelo_design_system/theme/app_text_styles.dart';");
      newContent = newContent.replaceAll(RegExp(r"import\s+'[^']*core/theme/app_colors\.dart';"), "import 'package:virelo_design_system/theme/app_colors.dart';");
      newContent = newContent.replaceAll(RegExp(r"import\s+'[^']*core/constants/app_spacing\.dart';"), "import 'package:virelo_design_system/constants/app_spacing.dart';");

      if (content != newContent) {
        entity.writeAsStringSync(newContent);
        print('Updated ${entity.path}');
      }
    }
  }
}

