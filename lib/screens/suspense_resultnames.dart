  import 'dart:async';
import 'dart:convert';
  import 'dart:math';
  import 'package:flutter/material.dart';
  import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
  import 'package:confetti/confetti.dart';
  import 'package:vibration/vibration.dart';
  import 'package:easy_localization/easy_localization.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  class SuspenseResultNames extends StatefulWidget {
    final List<String> names;
    final int count;

    SuspenseResultNames({required this.names, required this.count});

    @override
    _SuspenseResultNamesState createState() => _SuspenseResultNamesState();
  }

  class _SuspenseResultNamesState extends State<SuspenseResultNames>
      with SingleTickerProviderStateMixin {
    late ConfettiController _confettiController;
    final Random _random = Random();
    final StreamController<int> _selectedIndexController = StreamController<int>();
    List<String> _selectedNames = [];
    bool _isSpinning = false;
    int _currentCount = 0;
    late AnimationController _bgController;
    late Animation<Color?> _bgAnimation;

    @override
    void initState() {
      super.initState();
      _confettiController = ConfettiController(duration: Duration(seconds: 2));
      _bgController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 5),
      )..repeat(reverse: true);

      _bgAnimation = ColorTween(
        begin: Colors.blue.shade900,
        end: Colors.green.shade900,
      ).animate(_bgController);

      _startSpin();
    }

    @override
    void dispose() {
      _confettiController.dispose();
      _selectedIndexController.close();
      _bgController.dispose();
      super.dispose();
    }

    void _startSpin() async {
      if (_isSpinning || widget.names.isEmpty) return;
      setState(() => _isSpinning = true);

      List<String> tempNames = List.from(widget.names);

      for (int i = 0; i < widget.count; i++) {
        if (tempNames.isEmpty) break;

        setState(() => _currentCount = i + 1);
        await Future.delayed(Duration(seconds: 2));

        int finalIndex = _random.nextInt(tempNames.length);
        _selectedIndexController.add(finalIndex);

        await Future.delayed(Duration(milliseconds: 2500));

        String chosenName = widget.names[finalIndex];

        setState(() {
          _selectedNames.add(chosenName);
          tempNames.removeAt(finalIndex);
        });

        _confettiController.play();
        Vibration.vibrate(duration: 500);
        await Future.delayed(Duration(seconds: 2));
      }

      setState(() => _isSpinning = false);
      Navigator.pop(context, _selectedNames);

    }

    void _skipAnimation() {
      Navigator.pop(context, _selectedNames);
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: AnimatedBuilder(
          animation: _bgAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _bgAnimation.value ?? Colors.blue.shade900,
                    Colors.black,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: child,
            );
          },
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 30),
                    Text(
                      '${'drawing'.tr()} $_currentCount ${'of'.tr()} ${widget.count}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 50),
                    SizedBox(
                      width: 320,
                      height: 320,
                      child: FortuneWheel(
                        selected: _selectedIndexController.stream,
                        items: List.generate(widget.names.length, (index) {
                          return FortuneItem(
                            child: Text(
                              widget.names[index],
                              style: TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            style: FortuneItemStyle(
                              color: index % 2 == 0 ? Colors.purple : Colors.orange,
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
                        rotationCount: 8,
                      ),
                    ),
                    SizedBox(height: 30),
                    if (_selectedNames.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Text(
                          _selectedNames.last,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: _skipAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: AnimatedOpacity(
                          opacity: 0.5,
                          duration: Duration(seconds: 1),
                          child: Text(
                            'skip_anim'.tr(),
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
