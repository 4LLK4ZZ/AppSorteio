import 'dart:async';
import '../utils/random_utils.dart';
import 'dart:math';

class NumberDrawModel {
  int min;
  int max;
  int count;
  bool allowRepeats;
  bool suspense; // Adicionando suspense como parâmetro
  String filter;
  String order;
  List<int> results = [];

  NumberDrawModel({
    required this.min,
    required this.max,
    required this.count,
    required this.allowRepeats,
    required this.filter,
    required this.order,
    required this.suspense, // Parâmetro suspense
  });

  Future<List<int>> generateNumbers() async {
    results.clear(); // Limpa os resultados antes de iniciar

    // Cria a lista de números dentro do intervalo
    List<int> availableNumbers = List.generate(max - min + 1, (i) => min + i);

    // Aplica o filtro antes de sortear os números
    if (filter == 'even_numbers') {
      availableNumbers = availableNumbers.where((num) => num % 2 == 0).toList();
    } else if (filter == 'odd_numbers') {
      availableNumbers = availableNumbers.where((num) => num % 2 != 0).toList();
    }

    // Verifica se há números suficientes para evitar erro
    if (availableNumbers.length < count && !allowRepeats) {
      throw ArgumentError('Não há números suficientes após aplicar o filtro.');
    }

    // Sorteia os números respeitando o allowRepeats
    if (allowRepeats) {
      results = List.generate(count, (_) {
        return availableNumbers[RandomUtils.generateNumbers(
          min: 0,
          max: availableNumbers.length - 1,
          count: 1,
          allowRepeats: true,
        ).first];
      });
    } else {
      availableNumbers.shuffle();
      results = availableNumbers.take(count).toList();
    }

    // Se o suspense estiver ativado, simula a animação antes de mostrar os números
    if (suspense) {
      await Future.delayed(Duration(seconds: 3)); // Simula suspense
    }

    // Aplica a ordenação
    if (order == 'growing') {
      results.sort();
    } else if (order == 'descending') {
      results.sort((a, b) => b.compareTo(a));
    }

    return results;
  }
}
