import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:confetti/confetti.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sorteiodenumerosenomes/models/team_model.dart';
import 'package:vibration/vibration.dart';
import 'resultteams_screen.dart';

class SuspenseResultTeamsScreen extends StatefulWidget {
  final List<String> allNames;
  final int teamCount;
  final bool enableSuspense;

  SuspenseResultTeamsScreen({
    required this.allNames,
    required this.teamCount,
    required this.enableSuspense,
  });

  @override
  _SuspenseResultTeamsScreenState createState() => _SuspenseResultTeamsScreenState();
}

class _SuspenseResultTeamsScreenState extends State<SuspenseResultTeamsScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  final Random _random = Random();
  final BehaviorSubject<int> _selectedIndexController = BehaviorSubject<int>();
  late List<String> _availableNames;
  late List<List<String>> _teams;
  int _currentTeamIndex = 0;
  bool _isSpinning = false;
  String _currentWinner = "";
  late AnimationController _gradientController;
  bool _skipAnimation = false;

  final List<Color> wheelColors = [
    Colors.deepPurple,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    _gradientController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);

    _availableNames = List.from(widget.allNames);

    _teams = List.generate(widget.teamCount, (_) => []);

    _startSpin();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _selectedIndexController.close();
    _gradientController.dispose();
    super.dispose();
  }

  void _startSpin() async {
    if (_isSpinning || _availableNames.isEmpty) return;
    _isSpinning = true;

    while (_availableNames.length > 1) {
      if (_skipAnimation) return;

      await Future.delayed(Duration(milliseconds: 500));
      int finalIndex = _random.nextInt(_availableNames.length);
      _selectedIndexController.add(finalIndex);

      await Future.delayed(Duration(seconds: 2));

      if (_skipAnimation) return;

      String chosenName = _availableNames[finalIndex];

      setState(() {
        _currentWinner = chosenName;
        _teams[_currentTeamIndex].add(chosenName);
        _availableNames.removeAt(finalIndex);
        _currentTeamIndex = (_currentTeamIndex + 1) % widget.teamCount;
      });

      // Inicia a animação de confete
      _confettiController.play();

      // Vibe a cada sorteio
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500); // Vibra por 500ms
      }

      // Aguarda o tempo de animação do confete antes de continuar
      await Future.delayed(Duration(seconds: 2)); // Tempo para animação de confete

    }

    // Quando restar apenas um nome, adiciona ele e pula para os resultados
    if (_availableNames.length == 1) {
      _teams[_currentTeamIndex].add(_availableNames.first);
      _availableNames.clear();
      _isSpinning = false;
      Future.microtask(_goToResults);
      return;
    }

    _isSpinning = false;
    if (!_skipAnimation) _goToResults();
  }

  void _goToResults() {
    if (!mounted) return;
    if (_isSpinning) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ResultTeamScreen(teams: _teams, model: TeamModel(), enableSuspense: false),
      ),
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_skipAnimation) {
          setState(() => _skipAnimation = true);
          _goToResults();
        }
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(Colors.deepPurple, Colors.green, _gradientController.value)!,
                    Color.lerp(Colors.green, Colors.blueGrey, _gradientController.value)!,
                    Color.lerp(Colors.blueGrey, Colors.deepPurple, _gradientController.value)!,
                  ],
                ),
              ),
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 50,
                child: Text(
                  '${'raffling_teams'.tr()} ${_currentTeamIndex + 1}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: (_availableNames.length > 1)
                          ? FortuneWheel(
                        selected: _selectedIndexController.stream,
                        items: List.generate(_availableNames.length, (index) {
                          return FortuneItem(
                            child: Text(
                              _availableNames[index],
                              style: TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            style: FortuneItemStyle(
                              color: wheelColors[index % 2],
                              borderColor: Colors.white,
                              borderWidth: 3,
                            ),
                          );
                        }),
                        indicators: [
                          FortuneIndicator(
                            alignment: Alignment.topCenter,
                            child: TriangleIndicator(color: Colors.white),
                          ),
                        ],
                        animateFirst: false,
                        rotationCount: 5,
                      )
                          : Container(),
                    ),
                    SizedBox(height: 20),
                    _currentWinner.isNotEmpty
                        ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentWinner,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                        : Container(),
                  ],
                ),
              ),
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}