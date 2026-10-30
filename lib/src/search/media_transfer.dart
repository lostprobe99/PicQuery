import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:picquery_app/src/search/batch_files.dart';
import 'package:picquery_app/src/utils/all_files_access.dart';
import 'package:picquery_app/src/utils/toast_helper.dart';

bool _zh(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'zh';

/// Asks for a destination folder, then copies or moves [paths].
/// Returns null when the user cancels or still needs to grant file access.
Future<TransferOutcome?> transferPickedFiles(
  BuildContext context, {
  required List<String> paths,
  required bool move,
}) async {
  if (paths.isEmpty) return null;
  final zh = _zh(context);
  if (!await ensureAllFilesAccess()) {
    if (context.mounted) {
      Toast.showMessage(
        zh
            ? '请允许「所有文件访问权限」，回到应用后再移动'
            : 'Allow all-files access, then try the move again',
      );
    }
    return null;
  }
  if (!context.mounted) return null;
  final destination = await FilePicker.getDirectoryPath(
    dialogTitle: zh ? '选择目标文件夹' : 'Choose a folder',
  );
  if (destination == null || !context.mounted) return null;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );
  final outcome = await transferFiles(
    sources: paths,
    destinationDir: destination,
    move: move,
  );
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
    final verb = move ? (zh ? '移动' : 'Moved') : (zh ? '复制' : 'Copied');
    Toast.showMessage(
      zh
          ? '已$verb ${outcome.successCount} 张，失败 ${outcome.failureCount} 张'
          : '$verb ${outcome.successCount}, failed ${outcome.failureCount}',
    );
  }
  return outcome;
}
