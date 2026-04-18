import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalFileService {
  static Future<String> saveFileLocally(String sourcePath, String subDir) async {
    final File sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Source file does not exist: $sourcePath');
    }

    final directory = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(directory.path, subDir));
    
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final String fileName = p.basename(sourcePath);
    // Add timestamp to avoid collisions
    final String uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final targetPath = p.join(targetDir.path, uniqueName);

    await sourceFile.copy(targetPath);
    return targetPath;
  }
}
