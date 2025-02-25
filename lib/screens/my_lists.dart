import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import '../main.dart';

class MyListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> savedLists;

  const MyListScreen({super.key, required this.savedLists});

  @override
  _MyListScreenState createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  late List<Map<String, dynamic>> savedLists = [];
  late List<Map<String, dynamic>> filteredLists = [];
  String filterCriteria = 'date';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadSavedLists();
      });
    });
  }

  Future<void> loadSavedLists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('savedLists');
    if (encodedData != null) {
      List<dynamic> decodedList = jsonDecode(encodedData);
      setState(() {
        savedLists =
            decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
    void applyFilter() {
      setState(() {
        filteredLists = List.from(savedLists);

        // Aplicar filtro de pesquisa por nome
        if (searchController.text.isNotEmpty) {
          filteredLists = filteredLists.where((list) =>
              list['listName'].toLowerCase().contains(searchController.text.toLowerCase())
          ).toList();
        }

        // Aplicar ordenação com base no critério selecionado
        if (filterCriteria == 'date') {
          filteredLists.sort((a, b) => (b['saveDate'] ?? '').compareTo(a['saveDate'] ?? ''));
        } else if (filterCriteria == 'source') {
          filteredLists.sort((a, b) => (a['source'] ?? '').compareTo(b['source'] ?? ''));
        } else if (filterCriteria == 'name') {
          filteredLists.sort((a, b) => (a['listName'] ?? '').compareTo(b['listName'] ?? ''));
        }
      });
    }
  }

  Future<void> saveLists() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('savedLists', json.encode(savedLists));
  }

  Future<void> deleteList(int index) async {
    setState(() {
      savedLists.removeAt(index);
    });
    saveLists();
  }

  void editList(int index) {
    TextEditingController nameController = TextEditingController(
        text: savedLists[index]['listName'] ?? 'unnamed_list'.tr());
    TextEditingController namesController = TextEditingController(
        text: (savedLists[index]['names'] as List<dynamic>).join(', '));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_list'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'name.list'.tr()),
              ),
              TextField(
                controller: namesController,
                decoration: InputDecoration(labelText: 'name_commas'.tr()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                savedLists[index]['listName'] = nameController.text;
                savedLists[index]['names'] = namesController.text.split(', ');
              });
              saveLists();
              Navigator.of(context).pop();
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: savedLists.isEmpty
                ? Center(
              child: Icon(
                Icons.inbox, // Ícone indicando lista vazia
                color: Colors.white.withOpacity(0.3), // Transparente
                size: 95,
              ),
            )
                : ListView.builder(
              itemCount: savedLists.length,
              itemBuilder: (context, index) {
                return buildListTile(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildListTile(int index) {
    String listName = savedLists[index]['listName'] ?? 'unnamed_list'.tr();

    // Recuperando a data como String
    String saveDate = savedLists[index]['saveDate'] ?? 'unk_date'.tr();

    // Formatando a data para o formato desejado
    try {
      DateTime date = DateTime.parse(saveDate); // Supondo que a data esteja no formato ISO 8601
      saveDate = DateFormat('dd/MM/yyyy').format(date); // Formato desejado
    } catch (e) {
      // Se não for possível converter, usa a data original
      print('Erro ao formatar data: $e');
    }

    List<dynamic> names = savedLists[index]['names'] ?? [];
    String source = savedLists[index]['source'] ?? 'unk_source'.tr();
    int namesCount = names.length;

    return Card(
      color: Colors.blueGrey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listName,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                '${'saved_in'.tr()} $saveDate',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${'quantity_names'.tr()} $namesCount',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${'source'.tr()} $source',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              )
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () => editList(index),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => confirmDeletion(index, listName),
            ),
          ],
        ),
        onTap: () => showUseMenu(index),
      ),
    );
  }

  void confirmDeletion(int index, String listName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_deletion'.tr()),
        content: Text('${'confirm_delete'.tr()} "$listName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              deleteList(index);
              Navigator.of(context).pop();
            },
            child: Text('delete'.tr(), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showUseMenu(int index) {
    final selectedList = savedLists[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('choose_option'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('name_draw'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                  context,
                  '/names_config',
                  arguments: selectedList['names'],
                );
              },
            ),
            ListTile(
                title: Text('generate_team'.tr()),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/teams_config',
                    arguments: selectedList['names'],
                  );
                }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close_window'.tr()),
          ),
        ],
      ),
    );
  }
}