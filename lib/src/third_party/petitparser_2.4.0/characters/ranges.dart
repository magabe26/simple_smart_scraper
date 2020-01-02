import 'predicate.dart';

class RangesCharPredicate implements CharacterPredicate {
  final int length;
  final List<int> starts;
  final List<int> stops;

  const RangesCharPredicate(this.length, this.starts, this.stops)
      : assert(length != null, 'length must not be null'),
        assert(starts != null, 'starts must not be null'),
        assert(stops != null, 'stops must not be null');

  @override
  bool test(int value) {
    var min = 0;
    var max = length;
    while (min < max) {
      final mid = min + ((max - min) >> 1);
      final comp = starts[mid] - value;
      if (comp == 0) {
        return true;
      } else if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return 0 < min && value <= stops[min - 1];
  }

  @override
  bool isEqualTo(CharacterPredicate other) =>
      other is RangesCharPredicate &&
      other.length == length &&
      other.starts == starts &&
      other.stops == stops;
}
