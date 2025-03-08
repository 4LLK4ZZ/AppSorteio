import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../screens/resultnames_screen.dart';
import '../screens/suspense_resultnames.dart';
import '../models/names_model.dart';
import '../main.dart';
import 'my_lists.dart';

class NamesScreen extends StatefulWidget {

  @override
  _NamesScreenState createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  final NamesModel model = NamesModel();
  final TextEditingController _textController = TextEditingController();
  TextEditingController namesController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final List<dynamic>? receivedNames = ModalRoute.of(context)?.settings.arguments as List<dynamic>?;

    if (receivedNames != null && receivedNames.isNotEmpty) {
      namesController.text = receivedNames.map((e) => e.toString()).join(', ');
    }
  }
  void initState() {
    super.initState();
    model.loadSavedLists();
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

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'name_draw'.tr(),
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
                            namesController.clear();
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          model.addName(namesController.text);
                          namesController.clear();
                        });
                      },
                      icon: Icon(Icons.add, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: Colors.green,
                      ),
                      tooltip: "add_names".tr(),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyListScreen(
                                  savedLists: model.savedLists,
                                ),
                              ),
                            );
                          } else if (value == 'Upload de um arquivo') {
                            await model.importNames();
                            setState(() {});
                            _showSuccessDialog(context);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: 'Minhas listas',
                              child: Text('my_lists'.tr())),
                          PopupMenuItem(
                              value: 'Upload de um arquivo',
                              child: Text('upload'.tr())),
                        ],
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: 15, horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.green,
                          ),
                          onPressed: null,
                          child: Text(
                            'add_list'.tr(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ]
                ),
                SizedBox(height: 10),
                _buildCountSelector(),
                SizedBox(height: 10),
                SwitchListTile(
                  title: Text('enabled_suspense'.tr(),
                      style: TextStyle(color: Colors.white)),
                  value: model.enableSuspense,
                  onChanged: (value) =>
                      setState(() => model.enableSuspense = value),
                  activeColor: Colors.green,
                ),
                SwitchListTile(
                  title: Text('allow_repetion_names'.tr(),
                      style: TextStyle(color: Colors.white)),
                  value: model.allowRepetition,
                  onChanged: (value) =>
                      setState(() => model.allowRepetition = value),
                  activeColor: Colors.green,
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.green,
                  ),
                  onPressed: model.names.isNotEmpty
                      ? () {
                    if (model.enableSuspense) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SuspenseResultNames(
                            names: model.names,
                            count: model.count,
                          ),
                        ),
                      ).then((selectedNames) {
                        if (selectedNames != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResultNameScreen(
                                selectedNames: model.names,
                                fullList: model.names,
                                names: selectedNames,
                                count: model.count,
                                enableSuspense: false,
                                allowRepeats: model.allowRepetition,
                              ),
                            ),
                          );
                        }
                      });
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultNameScreen(
                            selectedNames: model.names,
                            fullList: model.names,
                            names: model.names,
                            count: model.count,
                            enableSuspense: model.enableSuspense,
                            allowRepeats: model.allowRepetition,
                          ),
                        ),
                      );
                    }
                  }
                      : null,
                  child: Text('draw'.tr(),
                  style: TextStyle(fontSize: 20, color: Colors.white),),
                ),
                SizedBox(height: 20),
                if (model.results.isNotEmpty)
                  Text(
                    'results: ${model.results.join(', ')}'.tr(),
                    style: TextStyle(fontSize: 18, color: Colors.white),
                    textAlign: TextAlign.center,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountSelector() {
    return Column(
      children: [
        Text(
          'quantity'.tr(),
          style: TextStyle(fontSize: 18, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Color(0xCC212121),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (model.count > 1) model.count--;
                  });
                },
              ),
              Text(
                '${model.count}',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  setState(() {
                    model.count++;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
