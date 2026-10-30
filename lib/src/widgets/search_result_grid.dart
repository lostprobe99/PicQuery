import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picquery_app/src/engine/api.dart';
import 'package:picquery_app/src/view/image_preview_view.dart';
import 'package:picquery_app/src/utils/adaptive_display.dart';
import 'package:picquery_app/src/utils/color_scheme.dart';

/// Grid display for search results with thumbnails and similarity scores.
class SearchResultGrid extends StatelessWidget {
  final List<SearchResult> results;

  /// Spacing above the first row of results.
  final double topPadding;
  final ValueChanged<SearchResult>? onResultOpened;
  final bool selectionMode;
  final Set<String> selectedPaths;
  final void Function(int index)? onToggleSelected;
  final void Function(int index)? onLongPress;

  const SearchResultGrid({
    super.key,
    required this.results,
    this.topPadding = 8,
    this.onResultOpened,
    this.selectionMode = false,
    this.selectedPaths = const {},
    this.onToggleSelected,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCrossAxisExtent = getAdaptiveMaxCrossAxisExtent(screenWidth);

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(8, topPadding, 8, 8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: 0.85,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _ResultCard(
          result: result,
          results: results,
          index: index,
          onResultOpened: onResultOpened,
          selected: selectedPaths.contains(result.filePath),
          selectionMode: selectionMode,
          onToggleSelected: onToggleSelected == null
              ? null
              : () => onToggleSelected!(index),
          onLongPress: onLongPress == null ? null : () => onLongPress!(index),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SearchResult result;
  final List<SearchResult> results;
  final int index;
  final ValueChanged<SearchResult>? onResultOpened;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onLongPress;
  late final focusNode = FocusNode();
  _ResultCard({
    required this.result,
    required this.results,
    required this.index,
    this.onResultOpened,
    this.selected = false,
    this.selectionMode = false,
    this.onToggleSelected,
    this.onLongPress,
  });

  void _openPreview(BuildContext context) {
    if (selectionMode) {
      onToggleSelected?.call();
      return;
    }
    focusNode.requestFocus();
    onResultOpened?.call(result);
    showContentInDialogOrPage<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          ImagePreviewView(results: results, initialIndex: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        // elevation: 0,
        clipBehavior: Clip.hardEdge,
        margin: EdgeInsets.all(2.5),
        child: InkWell(
          onTap: () => _openPreview(context),
          onLongPress: onLongPress,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pixelRatio = MediaQuery.devicePixelRatioOf(context);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(result.filePath),
                    cacheWidth: (constraints.maxWidth * pixelRatio).ceil(),
                    fit: BoxFit.cover,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    errorBuilder: (context, _, __) => Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (selectionMode)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: selected
                            ? context.colors.primary
                            : Colors.white,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
