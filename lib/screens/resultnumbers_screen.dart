import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sorteiodenumerosenomes/screens/numbers_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/widgets.dart' as pw;

class ResultNumbersScreen extends StatefulWidget {

  final List<int> results;
  final bool suspense;
  final DateTime drawDate;
  final int initialNumber;
  final int finalNumber;

  const ResultNumbersScreen({
    required this.results,
    required this.suspense,
    required this.drawDate,
    required this.initialNumber,
    required this.finalNumber,
  });

  @override
  _ResultNumbersScreenState createState() => _ResultNumbersScreenState();
}

class _ResultNumbersScreenState extends State<ResultNumbersScreen> with SingleTickerProviderStateMixin{
  late AnimationController _animationController;
  late Animation<double> _animation;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    saveToHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> saveToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> historyList = [];

    final String? encodedData = prefs.getString('historyList');
    if (encodedData != null) {
      List<dynamic> decodedList = jsonDecode(encodedData);
      historyList = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
    }

    Map<String, dynamic> newItem = {
      'date': widget.drawDate.toIso8601String(),
      'source': 'number_draw'.tr(),
      'type': 'numbers',
      'min': widget.initialNumber,
      'max': widget.finalNumber,
      'results': widget.results,
    };

    print("Novo item salvo no histórico: $newItem");

    historyList.insert(0, newItem);
    await prefs.setString('historyList', json.encode(historyList));

    print("Histórico atualizado: ${json.encode(historyList)}");
  }

  Future<void> _shareContent(String type) async {
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(
        widget.drawDate);
    String textContent = 'draw_held_in $formattedDate\nresults ${widget.results
        .join(', ')}'.tr();

    if (type == 'text') {
      Share.share(textContent);
    } else if (type == 'image') {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = File('${directory.path}/sorteio.png');
        await imagePath.writeAsBytes(image);
        Share.shareXFiles([XFile(imagePath.path)], text: 'draw_result'.tr());
      }
    } else if (type == 'pdf') {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) =>
              pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('draw_held_in $formattedDate'.tr(),
                      style: pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 16),
                  pw.Text('results'.tr(), style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text(widget.results.join(', '),
                      style: pw.TextStyle(fontSize: 20)),
                ],
              ),
        ),
      );
      final directory = await getTemporaryDirectory();
      final pdfPath = File('${directory.path}/sorteio.pdf');
      await pdfPath.writeAsBytes(await pdf.save());
      Share.shareXFiles([XFile(pdfPath.path)], text: 'draw_result'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade900.withOpacity(0.7),
                    Colors.purple.shade900.withOpacity(0.7),
                  ],
                  stops: [_animation.value, _animation.value + 0.5],
                ),
              ),
              child: Screenshot(
                controller: _screenshotController,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 16),
                      Text(
                        '${'draw_held_in'.tr()} ${DateFormat('dd/MM/yyyy HH:mm').format(widget.drawDate)}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 32),
                      Text(
                        'results'.tr(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true, // Evita scroll dentro do Column
                        physics: NeverScrollableScrollPhysics(), // Impede rolagem interna
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: (widget.results.length <= 5) ? widget.results.length : 5,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2, // Mantém os blocos mais largos para acomodar números grandes
                        ),
                        itemCount: widget.results.length,
                        itemBuilder: (context, index) => _buildResultNumber(widget.results[index]),
                      ),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/numbers_config');
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.share, color: Colors.white),
                              onSelected: _shareContent,
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'text', child: Text('share_text'.tr())),
                                PopupMenuItem(value: 'image', child: Text('share_image'.tr())),
                                PopupMenuItem(value: 'pdf', child: Text('share_pdf'.tr())),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultNumber(int num) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth, // Garante que o container use toda a largura disponível
          height: constraints.maxWidth / 2, // Define uma altura proporcional
          decoration: BoxDecoration(
            color: Colors.blue.shade900.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: FittedBox( // Ajusta o texto automaticamente ao espaço disponível
              fit: BoxFit.scaleDown,
              child: Text(
                '$num',
                style: TextStyle(
                  fontSize: 40, // Fonte grande para números pequenos, reduz automaticamente se precisar
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}