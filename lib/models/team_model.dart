import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../screens/resultteams_screen.dart';

class TeamModel {
  List<String> names = [];
  List<List<String>> teams = [];
  int teamSize = 2;
  bool enableSuspense = false;
  bool allowUnevenTeams = false;
  List<Map<String, dynamic>> savedLists = [];

  void addName(String name) {
    final newNames = name
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty && !names.contains(n))
        .toSet(); // Remove duplicatas

    names.addAll(newNames);
    print('📌 Nomes adicionados: $newNames');
  }

  Future<void> saveCurrentList(String listName) async {
    if (names.isEmpty) {
      print('❌ Não há nomes para salvar.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> existingLists = [];

    final savedListsJson = prefs.getString('savedLists');
    if (savedListsJson != null) {
      existingLists = List<Map<String, dynamic>>.from(json.decode(savedListsJson));
    }

    final newList = {
      'listName': listName,
      'names': List<String>.from(names),
      'saveDate': DateTime.now().toIso8601String(),
      'source': 'generate_teams'.tr(),
    };

    existingLists.add(newList);

    await prefs.setString('savedLists', json.encode(existingLists));
    print('✅ Lista salva com sucesso.');
  }

  Future<void> loadSavedLists() async {
    print('📂 Chamando loadSavedLists...');
    final prefs = await SharedPreferences.getInstance();
    final savedListsJson = prefs.getString('savedLists');

    if (savedListsJson == null) {
      print('❌ Nenhuma lista encontrada.');
      savedLists = []; // Evita erro ao acessar listas depois
      return;
    }

    try {
      List<dynamic> decodedData = json.decode(savedListsJson);

      // Convertendo explicitamente para List<Map<String, dynamic>>
      savedLists = decodedData.map<Map<String, dynamic>>((item) {
        return {
          'listName': item['listName'] as String,
          'names': List<String>.from(item['names'] ?? []),
          'saveDate': item.containsKey('saveDate') && item['saveDate'] is String
              ? item['saveDate'] // ✅ Mantém como String
              : DateTime.now().toIso8601String(), // ✅ Garante que seja sempre String
          'source': item['source'] ?? 'Desconhecido',
        };
      }).toList();


      print('✅ Listas carregadas: ${json.encode(savedLists)}');
    } catch (e) {
      print('❌ Erro ao carregar listas: $e');
      savedLists = []; // Evita crash caso haja erro ao decodificar JSON
    }
  }

  Future<void> importNames() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'docx'],
      );

      if (result != null) {
        String fileContent = '';

        if (result.files.single.bytes != null) {
          Uint8List fileBytes = result.files.single.bytes!;
          fileContent = utf8.decode(fileBytes);
        } else if (result.files.single.path != null) {
          File file = File(result.files.single.path!);
          fileContent = await file.readAsString();
        }

        final importedNames = fileContent
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && !names.contains(e))
            .toSet();

        names.addAll(importedNames);
        print("📂 Nomes importados: $importedNames");
      }
    } catch (e) {
      print("❌ Erro ao importar arquivo: $e");
    }
  }

  Future<void> generateTeams(BuildContext context) async {
    if (names.isEmpty || teamSize <= 0) return;

    List<String> availableNames = List.from(names);
    List<List<String>> generatedTeams = List.generate(teamSize, (_) => []);
    Random random = Random();

    int baseTeamSize = availableNames.length ~/ teamSize; // Quantidade base por equipe
    int extras = availableNames.length % teamSize; // Quantidade de sobras

    for (int i = 0; i < teamSize; i++) {
      int membersCount = baseTeamSize + (i < extras ? 1 : 0); // Distribui sobras entre as primeiras equipes

      for (int j = 0; j < membersCount; j++) {
        if (availableNames.isEmpty) break;
        int randomIndex = random.nextInt(availableNames.length);
        generatedTeams[i].add(availableNames.removeAt(randomIndex));
      }
    }

    teams = generatedTeams;
    print('✅ Equipes geradas: $teams');

    saveCurrentList('automatic_list'.tr()); // ⬅️ Salva automaticamente

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResultTeamScreen(teams: teams, model: TeamModel(), enableSuspense: enableSuspense),
      ),
    );
  }
}
