import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:easy_localization/easy_localization.dart';

class NamesModel {
  List<String> names = [];
  List<String> results = [];
  List<Map<String, dynamic>> savedLists = [];
  int count = 1;
  bool enableSuspense = false;
  bool allowRepetition = false;

  void addName(String text) {
    final newNames = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    names.addAll(newNames);
  }

  Future<void> loadSavedLists() async {
    print('📂 Chamando loadSavedLists...');
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('savedLists');
    if (encodedData != null) {
      savedLists = List<Map<String, dynamic>>.from(jsonDecode(encodedData));
      print('📂 Listas carregadas: $savedLists');
    }
    print('⚠️ Nenhuma lista salva encontrada.');
  }

  Future<void> debugSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('savedLists');

    print('🔍 Dados salvos no SharedPreferences: $savedData');
  }


  Future<void> importNames() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        String fileContent = "";

        if (file.bytes != null) {
          // Flutter Web: Ler a partir dos bytes
          fileContent = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          // Flutter Mobile/Desktop: Ler a partir do path
          String filePath = file.path!;

          if (filePath.endsWith('.txt')) {
            fileContent = await File(filePath).readAsString();
          } else if (filePath.endsWith('.docx') || filePath.endsWith('.doc')) {
            fileContent = await FlutterTesseractOcr.extractText(filePath);
          } else {
            return;
          }
        }

        final importedNames = fileContent
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        names.addAll(importedNames);
      }
    } catch (e) {}
  }

  Future<void> simulateRoulette() async {
    if (names.isEmpty || count <= 0) return;

    results = [];
    List<String> availableNames = allowRepetition
        ? List.from(names)  // Se permitir repetição, copia a lista original
        : names.toSet().toList();  // Se não permitir repetição, remove duplicatas

    Random random = Random();

    for (int i = 0; i < count; i++) {
      if (allowRepetition) {
        results.add(names[random.nextInt(names.length)]);
      } else {
        if (availableNames.isEmpty) break;
        results.add(availableNames.removeAt(random.nextInt(availableNames.length)));
      }

      if (enableSuspense) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }

    print('✅ Sorteio realizado: $results');
  }


  Future<void> saveList(String listName) async {
    if (listName.isNotEmpty) {
      savedLists.add({
        'listName': listName,
        'items': names.toList(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('savedLists', jsonEncode(savedLists));
      names.clear();
    }
  }
}
