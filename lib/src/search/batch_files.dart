import 'dart:io';

import 'package:path/path.dart' as p;

class TransferOutcome {
  final List<String> succeeded;
  final List<String> failed;

  const TransferOutcome({required this.succeeded, required this.failed});

  int get successCount => succeeded.length;
  int get failureCount => failed.length;
}

/// Copies or moves [sources] into [destinationDir]. Name collisions get a
/// numeric suffix. A file already in the destination is left in place.
Future<TransferOutcome> transferFiles({
  required List<String> sources,
  required String destinationDir,
  required bool move,
}) async {
  final destination = Directory(destinationDir);
  if (!await destination.exists()) {
    await destination.create(recursive: true);
  }
  final destCanonical = destination.absolute.path;
  final succeeded = <String>[];
  final failed = <String>[];

  for (final sourcePath in sources) {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        failed.add(sourcePath);
        continue;
      }
      final sourceCanonical = source.absolute.path;
      if (p.dirname(sourceCanonical) == destCanonical) {
        if (!move) succeeded.add(sourcePath);
        continue;
      }
      final targetPath = _uniquePath(destCanonical, p.basename(sourceCanonical));
      await source.copy(targetPath);
      if (move) {
        await source.delete();
      }
      succeeded.add(sourcePath);
    } catch (_) {
      failed.add(sourcePath);
    }
  }
  return TransferOutcome(succeeded: succeeded, failed: failed);
}

String _uniquePath(String directory, String fileName) {
  final extension = p.extension(fileName);
  final stem = p.basenameWithoutExtension(fileName);
  var candidate = p.join(directory, fileName);
  var index = 2;
  while (File(candidate).existsSync()) {
    candidate = p.join(directory, '$stem ($index)$extension');
    index++;
  }
  return candidate;
}
