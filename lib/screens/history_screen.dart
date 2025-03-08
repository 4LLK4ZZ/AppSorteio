import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<Map<String, dynamic>> historyList = [];
  String? selectedSource;
  bool sortByRecent = true;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadHistory();
  }

  Future<void> selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }


  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('historyList');
    if (encodedData != null) {
      List<dynamic> decodedList = jsonDecode(encodedData);
      setState(() {
        historyList =
            decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  Future<void> clearHistory() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Confirmação'),
            content: Text('Tem certeza que deseja apagar todo o histórico?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(context, true),
                  child: Text('Apagar')),
            ],
          ),
    ) ?? false;

    if (confirm) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('historyList');
      setState(() {
        historyList.clear();
      });
    }
  }

  String formatDate(String date) {
    try {
      DateTime dateTime = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  Widget buildHistoryTile(Map<String, dynamic> item) {
    String date = formatDate(item['date'] ?? '');
    String type = item['type'] ?? 'unknown';
    String source = item['source'] ?? 'Desconhecido';

    String details = '';
    if (type == 'numbers') {
      List<dynamic> results = item['results'] ?? [];
      details =
      '${'source'.tr()} $source\n(${'from'.tr()} ${item['min'] ?? '??'} ${'to'
          .tr()} ${item['max'] ?? '??'})\n${'results'.tr()} ${results.isNotEmpty
          ? results.join(', ')
          : 'Nenhum resultado'}';
    } else if (type == 'names') {
      List<dynamic> names = item['names'] ?? [];
      details =
      '${'source'.tr()} $source\n${'results'.tr()} ${names.isNotEmpty ? names
          .join(', ') : 'Nenhum nome'}';
    }
    else if (type == 'teams') {
      List<List<String>> teams = (item['teams'] as List?)
          ?.map((team) => List<String>.from(team))
          .toList() ?? [];

      details = '${'source'.tr()} $source\n' +
          (teams.isNotEmpty
              ? teams
              .asMap()
              .entries
              .map((e) => "${'teamm'.tr()} ${e.key + 1}: ${e.value.join(', ')}")
              .join('\n')
              : 'Nenhuma equipe gerada.');
    }

    return Card(

      color: Colors.blueGrey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        title: Text(date,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(details, style: TextStyle(color: Colors.white70)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => deleteHistoryItem(item), // ✅ Passa o item correto
            ),
            IconButton(
              icon: Icon(Icons.share, color: Colors.greenAccent),
              onPressed: () => shareHistory(item),
            ),
          ],
        ),
      ),
    );
  }

  void deleteHistoryItem(Map<String, dynamic> item) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmação'),
        content: Text('Tem certeza que deseja apagar este item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Apagar')),
            ],
          ),
    ) ?? false;

    if (confirm) {
      setState(() {
        historyList.removeWhere((element) => jsonEncode(element) == jsonEncode(item));
        // 🔹 Remove o item correto comparando JSONs
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('historyList', jsonEncode(historyList));
    }
  }

  void shareHistory(Map<String, dynamic> item) {
    String type = item['type'] ?? '';
    String source = item['source'] ?? '';
    String date = formatDate(item['date']);
    StringBuffer details = StringBuffer();

    if (type == 'numbers') {
      List<dynamic> results = item['results'] ?? [];
      details.writeln('${'date'.tr()} $date');
      details.writeln('${'source'.tr()} $source');
      details.writeln('(${ 'from'.tr() } ${item['min'] ?? '??'} ${'to'
          .tr()} ${item['max'] ?? '??'})');
      details.writeln('${'results'.tr()} ${results.isNotEmpty
          ? results.join(', ')
          : 'Nenhum resultado'}');
    } else if (type == 'names') {
      List<dynamic> names = item['names'] ?? [];
      details.writeln('${'date'.tr()} $date');
      details.writeln('${'source'.tr()} $source');
      details.writeln('${'results'.tr()} ${names.isNotEmpty
          ? names.join(', ')
          : 'Nenhum nome'}');
    } else if (type == 'teams') {
      var teams = item['teams'];

      details.writeln('${'date'.tr()} $date');
      details.writeln('${'source'.tr()} $source');
      details.writeln('${'teams'.tr()}:\n');

      if (teams is List) {
        // Caso os times sejam uma lista de listas (List<List<String>>)
        for (int i = 0; i < teams.length; i++) {
          if (teams[i] is List) {
            List<String> members = List<String>.from(teams[i]);
            details.writeln('${'teamm'.tr()} ${i + 1}: ${members.join(', ')}');
          }
        }
      } else if (teams is Map<String, dynamic>) {
        // Caso os times estejam salvos como um mapa (Map<String, List<String>>)
        teams.forEach((teamName, members) {
          if (members is List) {
            details.writeln('- $teamName: ${members.join(', ')}');
          }
        });
      } else {
        details.writeln('Nenhuma equipe gerada.');
      }
    }

    Share.share(details.toString());
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 Passo 1: Verificar os dados antes do filtro
    print("Lista original antes do filtro:");
    for (var item in historyList) {
      print("Item: ${item['date']}");
    }

    List<Map<String, dynamic>> filteredList = List.from(historyList);

// Filtragem por source
    if (selectedSource != null) {
      filteredList = filteredList.where((item) => item['source'] == selectedSource).toList();
    }

// 🔍 Passo 2: Verificar filtragem por intervalo de datas
    if (startDate != null && endDate != null) {
      print("Filtrando de ${startDate!.toIso8601String()} até ${endDate!.toIso8601String()}");

      filteredList = filteredList.where((item) {
        String? dateString = item['date'];
        if (dateString == null || dateString.isEmpty) {
          print("Item sem data ignorado.");
          return false;
        }

        DateTime? itemDate = DateTime.tryParse(dateString);
        if (itemDate == null) {
          print("Data inválida ignorada: $dateString");
          return false;
        }

        // 🔹 Normaliza as datas para ignorar horas/minutos/segundos
        DateTime itemDateOnly = DateTime(itemDate.year, itemDate.month, itemDate.day);
        DateTime startDateOnly = DateTime(startDate!.year, startDate!.month, startDate!.day);
        DateTime endDateOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);

        bool dentroIntervalo = itemDateOnly.isAtSameMomentAs(startDateOnly) ||
            itemDateOnly.isAtSameMomentAs(endDateOnly) ||
            (itemDateOnly.isAfter(startDateOnly) && itemDateOnly.isBefore(endDateOnly));

        print("Item ${item['date']} (só data: $itemDateOnly) está dentro do intervalo? $dentroIntervalo");
        return dentroIntervalo;
      }).toList();
    }

// 🔍 Passo 3: Verificar ordenação
    print("Ordenando por ${sortByRecent ? 'mais recente' : 'mais antigo'}");

    filteredList = List.from(filteredList); // Garante que está criando uma nova lista

    filteredList.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
      DateTime dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
      return sortByRecent ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });


// 🔍 Passo 4: Imprimir a lista final
    print("Lista final após filtro e ordenação:");
    for (var item in filteredList) {
      print("Item: ${item['date']}");
    }


    return SafeArea(
      child: Stack(
        children: [
          AppBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text('history_draw'.tr(), style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                      Spacer(),
                      IconButton(
                        icon: Icon(
                            Icons.delete_forever, color: Colors.redAccent),
                        onPressed: () => clearHistory(),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DropdownButton<String>(
                            value: selectedSource,
                            hint: Text('filter_origin'.tr(),
                                style: TextStyle(color: Colors.white)),
                            dropdownColor: Colors.grey[800],
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text('all'.tr(),
                                    style: TextStyle(color: Colors.white)),
                              ),
                              ...historyList.map((e) => e['source'].toString())
                                  .toSet()
                                  .map((source) {
                                return DropdownMenuItem<String>(
                                  value: source,
                                  child: Text(source,
                                      style: TextStyle(color: Colors.white)),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedSource = value;
                              });
                            },
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.date_range, color: Colors.white),
                            label: Text('Filtrar por data',
                                style: TextStyle(color: Colors.white)),
                            onPressed: selectDateRange,
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  sortByRecent ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    sortByRecent = !sortByRecent;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(child: Text('draw_saved'.tr(),
                        style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return buildHistoryTile(filteredList[index]); // ✅ Passa o item diretamente
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}