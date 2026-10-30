import 'package:flutter_test/flutter_test.dart';
import 'package:picquery_app/src/search/selection_state.dart';

void main() {
  const order = ['a', 'b', 'c', 'd', 'e'];

  test('a second long-press selects the inclusive range', () {
    final started = SelectionState.of(order).longPress(1);
    expect(started.selected, {'b'});

    final ranged = started.longPress(4);
    expect(ranged.selected, {'b', 'c', 'd', 'e'});

    final backward = ranged.longPress(0);
    expect(backward.selected, {'a', 'b', 'c', 'd', 'e'});
  });

  test('tap toggles one item and the next range starts there', () {
    final selected = SelectionState.of(order).longPress(0).toggle(2).longPress(4);
    expect(selected.selected, {'a', 'c', 'd', 'e'});
  });

  test('retarget drops moved files and keeps the anchor item', () {
    final selected = SelectionState.of(order).longPress(1).longPress(3);
    final next = selected.retarget(['b', 'd', 'e']);
    expect(next.selected, {'b', 'd'});
    expect(next.order[next.anchor!], 'd');
  });
}
