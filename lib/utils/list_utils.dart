import 'dart:math';

class ListUtils {
  static List<T> shuffleList<T>(List<T> list) {
    final random = Random();
    final shuffled = List<T>.from(list);
    for (var i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }
}
