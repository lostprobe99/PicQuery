import 'package:flutter/material.dart';
import 'package:picquery_app/src/utils/color_scheme.dart';

class SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onSelectAll;
  final VoidCallback? onCopy;
  final VoidCallback? onMove;
  final VoidCallback? onShare;
  final VoidCallback onCancel;

  const SelectionBar({
    super.key,
    required this.count,
    required this.onSelectAll,
    required this.onCopy,
    required this.onMove,
    required this.onShare,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    return SafeArea(
      child: Material(
        color: context.colors.surfaceContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  zh ? '再长按另一张，选中两张之间的全部' : 'Long-press another item to select the range',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 12),
                Text(zh ? '已选 $count' : '$count selected'),
                const Spacer(),
                IconButton(
                  tooltip: zh ? '全选' : 'Select all',
                  onPressed: onSelectAll,
                  icon: const Icon(Icons.select_all),
                ),
                IconButton(
                  tooltip: zh ? '复制到文件夹' : 'Copy to folder',
                  onPressed: count == 0 ? null : onCopy,
                  icon: const Icon(Icons.folder_copy_outlined),
                ),
                IconButton(
                  tooltip: zh ? '移动到文件夹' : 'Move to folder',
                  onPressed: count == 0 ? null : onMove,
                  icon: const Icon(Icons.drive_file_move_outline),
                ),
                IconButton(
                  tooltip: zh ? '分享' : 'Share',
                  onPressed: count == 0 ? null : onShare,
                  icon: const Icon(Icons.share_outlined),
                ),
                IconButton(
                  tooltip: zh ? '取消' : 'Cancel',
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
