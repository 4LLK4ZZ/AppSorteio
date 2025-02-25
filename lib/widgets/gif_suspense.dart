import 'package:flutter/material.dart';

class SuspenseGif extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onComplete;
  final String gifPath;

  SuspenseGif({required this.isVisible, required this.onComplete, required this.gifPath});

  @override
  Widget build(BuildContext context) {
    return isVisible
        ? FutureBuilder(
      future: Future.delayed(Duration(seconds: 3)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          onComplete(); // Chama o callback ao final do suspense
          return SizedBox.shrink(); // Retira o GIF
        }
        return Center(
          child: Image.asset('lib/assets/gifs/tambor.gif'),
        );
      },
    )
        : SizedBox.shrink();
  }
}
