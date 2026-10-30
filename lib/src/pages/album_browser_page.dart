import 'package:flutter/material.dart';
import 'package:picquery_app/src/engine/api.dart';
import 'package:picquery_app/src/managers/album_manager.dart';
import 'package:picquery_app/src/search/media_transfer.dart';
import 'package:picquery_app/src/search/selection_state.dart';
import 'package:picquery_app/src/utils/color_scheme.dart';
import 'package:picquery_app/src/widgets/search_result_grid.dart';
import 'package:picquery_app/src/widgets/selection_bar.dart';
import 'package:share_plus/share_plus.dart';

/// Every indexed picture in one album, with the same selection as search.
class AlbumBrowserPage extends StatefulWidget {
  final Album album;

  const AlbumBrowserPage({super.key, required this.album});

  @override
  State<AlbumBrowserPage> createState() => _AlbumBrowserPageState();
}

class _AlbumBrowserPageState extends State<AlbumBrowserPage> {
  late List<SearchResult> _images = listAlbumImages(albumId: widget.album.id);
  late SelectionState _selection = SelectionState.of(
    _images.map((item) => item.filePath).toList(),
  );

  void _replaceImages(List<SearchResult> images) {
    _images = images;
    _selection = _selection.retarget(images.map((item) => item.filePath).toList());
  }

  Future<void> _transfer({required bool move}) async {
    final paths = _selection.selected.toList();
    final outcome = await transferPickedFiles(context, paths: paths, move: move);
    if (!mounted || outcome == null || !move || outcome.succeeded.isEmpty) return;
    final done = outcome.succeeded.toSet();
    forgetMovedImages(outcome.succeeded);
    await albumManager.reload();
    if (!mounted) return;
    setState(() {
      _replaceImages(
        _images.where((item) => !done.contains(item.filePath)).toList(),
      );
    });
  }

  Future<void> _share() async {
    final paths = _selection.selected.toList();
    if (paths.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(files: paths.map(XFile.new).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final title = widget.album.displayName?.trim().isNotEmpty == true
        ? widget.album.displayName!
        : widget.album.albumPath;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _images.isEmpty
          ? Center(child: Text(zh ? '这个相册里还没有已索引的图片' : 'No indexed images'))
          : Column(
              children: [
                if (!_selection.active)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      zh
                          ? '长按一张开始选择，再长按另一张，选中中间的全部'
                          : 'Long-press one image, then another, to select the range',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                Expanded(
                  child: SearchResultGrid(
                    results: _images,
                    selectionMode: _selection.active,
                    selectedPaths: _selection.selected,
                    onLongPress: (index) =>
                        setState(() => _selection = _selection.longPress(index)),
                    onToggleSelected: (index) =>
                        setState(() => _selection = _selection.toggle(index)),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _selection.active
          ? SelectionBar(
              count: _selection.selected.length,
              onSelectAll: () => setState(() => _selection = _selection.selectAll()),
              onCopy: () => _transfer(move: false),
              onMove: () => _transfer(move: true),
              onShare: _share,
              onCancel: () => setState(() => _selection = _selection.clear()),
            )
          : null,
    );
  }
}
