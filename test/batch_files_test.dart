import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picquery_app/src/search/batch_files.dart';

void main() {
  test('copy renames collisions and move removes the source', () async {
    final root = await Directory.systemTemp.createTemp('picquery-batch');
    addTearDown(() => root.delete(recursive: true));
    final sourceDir = Directory('${root.path}/src')..createSync();
    final destDir = Directory('${root.path}/dest')..createSync();
    final first = File('${sourceDir.path}/a.jpg')..writeAsStringSync('one');
    final second = File('${sourceDir.path}/b.jpg')..writeAsStringSync('two');
    File('${destDir.path}/a.jpg').writeAsStringSync('already');

    final copied = await transferFiles(
      sources: [first.path, second.path],
      destinationDir: destDir.path,
      move: false,
    );
    expect(copied.failureCount, 0);
    expect(File('${destDir.path}/a.jpg').readAsStringSync(), 'already');
    expect(File('${destDir.path}/a (2).jpg').readAsStringSync(), 'one');
    expect(first.existsSync(), isTrue);

    final moved = await transferFiles(
      sources: [second.path],
      destinationDir: destDir.path,
      move: true,
    );
    expect(moved.successCount, 1);
    expect(second.existsSync(), isFalse);
    expect(File('${destDir.path}/b.jpg').readAsStringSync(), 'two');
  });
}
