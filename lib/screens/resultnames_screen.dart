import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'suspense_resultnames.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class ResultNameScreen extends StatefulWidget {
  final List<String> names;
  final int count;
  final bool enableSuspense;
  final bool allowRepeats;
  final List<String> selectedNames;
  final List<String> fullList;

  ResultNameScreen({
    required this.names,
    required this.count,
    required this.enableSuspense,
    required this.allowRepeats,
    required this.selectedNames,
    required this.fullList,
  });

  @override
  _ResultNameScreenState createState() => _ResultNameScreenState();
}

class _ResultNameScreenState extends State<ResultNameScreen>
    with SingleTickerProviderStateMixin {
  ScreenshotController screenshotController = ScreenshotController();
  late AnimationController _animationController;
  late Animation<Color?> _backgroundAnimation;
  List<String> _selectedNames = [];
  late DateTime _drawDate;

  @override
  void initState() {
    super.initState();
    _drawDate = DateTime.now();
    _selectedNames = List.from(widget.selectedNames);

    _animationController =
    AnimationController(vsync: this, duration: Duration(seconds: 5))
      ..repeat(reverse: true);

    _backgroundAnimation = ColorTween(
      begin: Colors.blue.shade900.withOpacity(0.6),
      end: Colors.purple.shade900.withOpacity(0.6),
    ).animate(_animationController);

    if (widget.enableSuspense) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToSuspense());
    } else {
      _drawNames();
    }
    saveToHistory();
    saveCurrentList('automatic_list'.tr());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _drawNames() {
    List<String> namesPool = List.from(widget.names);
    if (widget.allowRepeats) {
      _selectedNames = List.generate(widget.count, (_) {
        namesPool.shuffle();
        return namesPool.first;
      });
    } else {
      _selectedNames = (namesPool..shuffle()).take(widget.count).toList();
    }
    setState(() {});
  }

  void _navigateToSuspense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuspenseResultNames(
          names: _selectedNames,
          count: widget.count,
        ),
      ),
    );

    if (result != null) {
      if (result is List<String>) {
        setState(() {
          _selectedNames = result;
        });
      } else if (result is Map<String, List<String>>) {
        setState(() {
          _selectedNames = result['selectedNames'] ?? [];
        });
      } else {
        print("⚠️ Tipo inesperado retornado: ${result.runtimeType}");
      }
    }
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
      'date': _drawDate.toIso8601String(),
      'source': 'name_draw'.tr(),
      'type': 'names',
      'names': _selectedNames.isNotEmpty ? _selectedNames : ['Nenhum nome encontrado'],
    };

    if (historyList.isNotEmpty && jsonEncode(historyList.first['names']) == jsonEncode(newItem['names'])) {
      print("O sorteio já foi salvo, evitando duplicação.");
      return;
    }

    print("Novo item salvo no histórico: $newItem");

    historyList.insert(0, newItem);
    await prefs.setString('historyList', json.encode(historyList));

    print("Histórico atualizado: ${json.encode(historyList)}");
  }

  Future<void> saveCurrentList(String listName) async {
    if (widget.names.isEmpty) {
      print('⚠️ Lista vazia, não será salva.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> existingLists = [];

    final savedListsJson = prefs.getString('savedLists');
    if (savedListsJson != null) {
      existingLists =
      List<Map<String, dynamic>>.from(json.decode(savedListsJson));
    }

    final newList = {
      'listName': listName,
      'names': List<String>.from(widget.fullList),
      'saveDate': DateTime.now().toIso8601String(),
      'source': 'name_draw'.tr(),
    };

    existingLists.add(newList);

    await prefs.setString('savedLists', json.encode(existingLists));

    print('✅ Lista salva: ${json.encode(existingLists)}'); // 🛠️ Verifica o salvamento
  }

  Future<void> _shareImage() async {
    final image = await screenshotController.capture();
    if (image == null) return;

    final directory = await getTemporaryDirectory();
    final imagePath = File("${directory.path}/nomes.png");
    await imagePath.writeAsBytes(image);

    await Share.shareXFiles(
        [XFile(imagePath.path)], text: 'name_draw'.tr());
  }

  Future<void> _sharePdf() async {
    final pdf = pw.Document();
    final directory = await getApplicationDocumentsDirectory();
    final pdfPath = '${directory.path}/resultado.pdf';

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text('Sorteio realizado em ${DateFormat("dd/MM/yyyy HH:mm").format(_drawDate)}', style: pw.TextStyle(fontSize: 18)),
            ..._selectedNames.map((name) => pw.Text(name, style: pw.TextStyle(fontSize: 22))),
          ],
        ),
      ),
    );

    final file = File(pdfPath);
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(pdfPath)], text: 'Sorteio realizado!');
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_backgroundAnimation.value!, Colors.black.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Spacer(), // Adicionando espaço superior para descer os elementos
                    Text(
                      'results'.tr(),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '${'draw_held_in'.tr()} ${DateFormat("dd/MM/yyyy HH:mm").format(_drawDate)}',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(height: 30),
                    ..._selectedNames.map((name) => Container(
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    )),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/names_config');
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.share, color: Colors.white),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.black.withOpacity(0.8),
                            builder: (_) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: Icon(Icons.text_fields, color: Colors.white),
                                  title: Text('share_text'.tr(), style: TextStyle(color: Colors.white)),
                                  onTap: () => Share.share(_selectedNames.join(", ")),
                                ),
                                ListTile(
                                  leading: Icon(Icons.image, color: Colors.white),
                                  title: Text('share_image'.tr(), style: TextStyle(color: Colors.white)),
                                  onTap: _shareImage,
                                ),
                                ListTile(
                                  leading: Icon(Icons.picture_as_pdf, color: Colors.white),
                                  title: Text('share_pdf'.tr(), style: TextStyle(color: Colors.white)),
                                  onTap: _sharePdf,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}