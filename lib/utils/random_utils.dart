import 'dart:math';

class RandomUtils {
  static List<int> generateNumbers({
    required int min,
    required int max,
    required int count,
    required bool allowRepeats,
  }) {
    final random = Random();
    final range = List<int>.generate(max - min + 1, (i) => min + i);

    if (allowRepeats) {
      return List<int>.generate(
        count,
            (_) => range[random.nextInt(range.length)],
      );
    } else {
      range.shuffle(random);
      return range.take(count).toList();
    }
  }
}