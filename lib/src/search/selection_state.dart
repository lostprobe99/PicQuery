/// Grid selection. A long-press starts a selection or, once an anchor exists,
/// selects every item between the anchor and the pressed item.
class SelectionState {
  final List<String> order;
  final Set<String> selected;
  final int? anchor;
  final bool active;

  const SelectionState({
    required this.order,
    required this.selected,
    required this.anchor,
    required this.active,
  });

  factory SelectionState.of(List<String> order) {
    return SelectionState(
      order: order,
      selected: const {},
      anchor: null,
      active: false,
    );
  }

  SelectionState longPress(int index) {
    if (index < 0 || index >= order.length) return this;
    if (!active || anchor == null) {
      return SelectionState(
        order: order,
        selected: {...selected, order[index]},
        anchor: index,
        active: true,
      );
    }
    final start = anchor! < index ? anchor! : index;
    final end = anchor! < index ? index : anchor!;
    final next = {...selected};
    for (var i = start; i <= end; i++) {
      next.add(order[i]);
    }
    return SelectionState(
      order: order,
      selected: next,
      anchor: index,
      active: true,
    );
  }

  SelectionState toggle(int index) {
    if (index < 0 || index >= order.length) return this;
    final path = order[index];
    final next = {...selected};
    if (!next.add(path)) next.remove(path);
    return SelectionState(
      order: order,
      selected: next,
      anchor: index,
      active: true,
    );
  }

  SelectionState selectAll() {
    return SelectionState(
      order: order,
      selected: order.toSet(),
      anchor: order.isEmpty ? null : 0,
      active: true,
    );
  }

  SelectionState clear() {
    return SelectionState(
      order: order,
      selected: const {},
      anchor: null,
      active: false,
    );
  }

  /// Drops paths that are no longer on screen and keeps the anchor when that
  /// item is still present.
  SelectionState retarget(List<String> nextOrder) {
    final nextSelected = selected.intersection(nextOrder.toSet());
    final anchorPath = anchor == null || anchor! < 0 || anchor! >= order.length
        ? null
        : order[anchor!];
    final nextAnchor = anchorPath == null ? null : nextOrder.indexOf(anchorPath);
    return SelectionState(
      order: nextOrder,
      selected: nextSelected,
      anchor: nextAnchor == null || nextAnchor < 0 ? null : nextAnchor,
      active: active && nextSelected.isNotEmpty,
    );
  }
}
