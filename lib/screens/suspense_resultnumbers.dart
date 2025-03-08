import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vibration/vibration.dart';
import '../models/numbers_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'resultnumbers_screen.dart';

class SuspenseResultNumbers extends StatefulWidget {
  final NumberDrawModel drawModel;
  final Function(List<int>) onFinish;
  final int initialNumber;
  final int quantity;
  final int finalNumber;
  final int suspenseDuration;
  final String filter;
  final String order;
  final bool allowRepeats;


  const SuspenseResultNumbers({
    required this.onFinish,
    required this.initialNumber,
    required this.quantity,
    required this.finalNumber,
    this.suspenseDuration = 3,
    required this.filter,
    required this.order,
    required this.drawModel,
    required this.allowRepeats,
  });

  @override
  _SuspenseResultNumbersState createState() => _SuspenseResultNumbersState();
}

class _SuspenseResultNumbersState extends State<SuspenseResultNumbers>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  final BehaviorSubject<int> _selectedIndexController = BehaviorSubject<int>();
  late AnimationController _gradientController;
  bool _isSpinning = false;
  bool _skipAnimation = false;
  final Random _random = Random();
  late List<int> numbers;
  List<int> selectedNumbers = [];
  int currentDraw = 1;

  @override
  void initState() {
    super.initState();
    numbers = List.generate(
      widget.finalNumber - widget.initialNumber + 1,
          (index) => widget.initialNumber + index,
    );

    _confettiController = ConfettiController(duration: Duration(seconds: 3));
    _gradientController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);

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
    if (_isSpinning || _skipAnimation) return;
    _isSpinning = true;
    selectedNumbers.clear();
    currentDraw = 1;

    List<int> generatedNumbers = await widget.drawModel.generateNumbers();

    for (int i = 0; i < widget.quantity; i++) {
      if (_skipAnimation) break;

      setState(() {
        currentDraw = i + 1;
      });

      for (int j = 0; j < widget.suspenseDuration * 7; j++) {
        int tempIndex = _random.nextInt(numbers.length);
        _selectedIndexController.add(tempIndex);
        await Future.delayed(Duration(milliseconds: 50 + j * 10));
        if (_skipAnimation) return;
      }

      int finalNumber = generatedNumbers[i];
      selectedNumbers.add(finalNumber);

      int finalIndex = numbers.indexOf(finalNumber);
      _selectedIndexController.add(finalIndex);

      _confettiController.play();
      await Future.delayed(Duration(milliseconds: 300));
      _confettiController.stop();

      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 300);
      }

      await Future.delayed(Duration(milliseconds: 800));
    }

    if (mounted && selectedNumbers.length == widget.quantity) {
      _isSpinning = false;
      _navigateToResults();
    }
  }



  void _navigateToResults() {
    if (selectedNumbers.length < widget.quantity) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultNumbersScreen(
          results: selectedNumbers,
          suspense: true,
          drawDate: DateTime.now(),
          finalNumber: widget.finalNumber,
          initialNumber: widget.initialNumber,
        ),
      ),
    );
  }

  void _skipToResult() async {
    setState(() {
      _skipAnimation = true;
    });

    if (selectedNumbers.isEmpty || selectedNumbers.length < widget.quantity) {
      List<int> generatedNumbers = await widget.drawModel.generateNumbers();
      selectedNumbers = generatedNumbers.take(widget.quantity).toList();
    }

    if (mounted && selectedNumbers.length == widget.quantity) {
      _navigateToResults();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _skipToResult,
        child: AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.blue.withOpacity(0.7),
                  ],
                ),
              ),
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${'drawing'.tr()} $currentDraw ${'of'.tr()} ${widget.quantity}",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      selectedNumbers.isNotEmpty ? selectedNumbers.last.toString() : "??",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: selectedNumbers.isNotEmpty ? Colors.white : Colors.white.withOpacity(0.4), // Esmaecido antes do primeiro número
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    height: 200,
                    child: FortuneBar(
                      selected: _selectedIndexController.stream,
                      items: numbers.map((number) {
                        return FortuneItem(
                          child: Text(
                            number.toString(),
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FortuneItemStyle(
                            color: Colors.transparent,
                            borderColor: Colors.purple.withOpacity(0.2),
                            borderWidth: 0,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
              ),
              Positioned(
                bottom: 50,
                child: GestureDetector(
                  onTap: _skipToResult,
                  child: Text(
                    'skip_anim'.tr(),
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
