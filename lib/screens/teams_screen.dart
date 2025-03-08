import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sorteiodenumerosenomes/models/team_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'my_lists.dart';
import '../main.dart';
import 'suspense_resultsteams.dart';
import 'resultteams_screen.dart';

class TeamsScreen extends StatefulWidget {
  final String? initialNames; // Adicionando para receber nomes já carregados

  TeamsScreen({this.initialNames});

  @override
  _TeamsScreenState createState() => _TeamsScreenState();

}

class _TeamsScreenState extends State<TeamsScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController namesController = TextEditingController();
  final TeamModel model = TeamModel();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final List<dynamic>? receivedNames = ModalRoute.of(context)?.settings.arguments as List<dynamic>?;

    if (receivedNames != null && receivedNames.isNotEmpty) {
      namesController.text = receivedNames.map((e) => e.toString()).join(', ');
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('success'.tr()),
          content: Text('names_imported'.tr()),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _addNames() {
    if (namesController.text.isNotEmpty) {
      setState(() {
        List<String> newNames =
            namesController.text.split(',').map((e) => e.trim()).toList();
        model.names.addAll(newNames);
        namesController.clear();
        _textController.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Carrega nomes iniciais, se houver
    if (widget.initialNames != null && widget.initialNames!.isNotEmpty) {
      List<String> loadedNames = widget.initialNames!.split(',').map((e) => e.trim()).toList();
      setState(() {
        model.names.addAll(loadedNames);
        namesController.text = model.names.join(', ');
      });
    }

    // Carrega listas salvas sem atribuir automaticamente
    model.loadSavedLists();
  }


  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon:
                            Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/');
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'generate_teams'.tr(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                            controller: namesController,
                            decoration: InputDecoration(
                              labelText:
                                  'textfield_names'.tr(),
                              fillColor: Color(0xCC212121),
                              filled: true,
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) {
                              setState(() {
                                model.addName(namesController.text);
                                namesController.text = model.names.join(', ');
                              });
                            }),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            model.addName(namesController.text);
                            namesController.text = model.names.join(', ');
                            namesController.clear();// Atualiza o campo de texto
                          });
                        },
                        icon: Icon(Icons.add, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.green,
                        ),
                        tooltip: 'add_names'.tr(),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PopupMenuButton<String>(
                        onSelected: (String value) async {
                          if (value == 'Minhas listas') {
                            await model
                                .loadSavedLists(); // Aguarde o carregamento antes de continuar

                            final selectedNames = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyListScreen(
                                  savedLists: model.savedLists,
                                ),
                              ),
                            );
                            if (selectedNames != null && selectedNames is List<String>) {
                              setState(() {
                                model.names.clear();
                                model.names.addAll(selectedNames);
                                namesController.text = model.names.join(', ');
                              });
                            }
                          } else if (value == 'Upload de um arquivo') {
                            model.importNames().then((_) {
                              setState(() {});
                              _showSuccessDialog(context);
                            });
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'Minhas listas',
                            child: Text('my_lists'.tr()),
                          ),
                          PopupMenuItem<String>(
                            value: 'Upload de um arquivo',
                            child: Text('upload'.tr()),
                          ),
                        ],
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'add_list'.tr(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'quantity_teams'.tr(),
                    style: TextStyle(fontSize: 18, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xCC212121),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (model.teamSize > 1) model.teamSize--;
                            });
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${model.teamSize}',
                              style:
                                  TextStyle(fontSize: 24, color: Colors.white),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              model.teamSize++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  SwitchListTile(
                    title: Text(
                      'enabled_suspense'.tr(),
                      style: TextStyle(color: Colors.white),
                    ),
                    value: model.enableSuspense,
                    onChanged: (value) {
                      setState(() {
                        model.enableSuspense = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  SizedBox(height: 10),
                  SwitchListTile(
                    title: Text(
                      'allow_team_imbalance'.tr(),
                      style: TextStyle(color: Colors.white),
                    ),
                    value: model.allowUnevenTeams,
                    onChanged: (value) {
                      setState(() {
                        model.allowUnevenTeams = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: (model.names.isNotEmpty &&
                        (model.names.length % model.teamSize == 0 || model.allowUnevenTeams))
                        ? () {
                      model.generateTeams(context);

                      if (model.teams.length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('two_team_size'.tr())),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => model.enableSuspense
                              ? SuspenseResultTeamsScreen(
                              allNames: model.names,
                              teamCount: model.teamSize,
                              enableSuspense: model.enableSuspense)
                              : ResultTeamScreen(
                              teams: model.teams,
                              model: TeamModel(),
                              enableSuspense: model.enableSuspense),
                        ),
                      );
                    }
                        : null,
                    child: Text('generate'.tr(),
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: (model.names.isNotEmpty &&
                              (model.names.length % model.teamSize == 0 ||
                                  model.allowUnevenTeams))
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, // Alinha à direita
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: model.names.isNotEmpty ? Colors.red : Colors.grey, // Cinza quando desativado
                        ),
                        onPressed: model.names.isNotEmpty
                            ? () {
                          setState(() {
                            model.names.clear();
                          });
                        }
                            : null, // Desativa o botão se não houver nomes
                        child: Text(
                          'clear_all'.tr(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  if (model.names.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: model.names.length,
                      itemBuilder: (context, index) => Container(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: Color(0xCC212121),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: ListTile(
                          title: Text(
                            model.names[index],
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => model.names.removeAt(index)),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
