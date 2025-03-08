import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../main.dart';
import '../screens/resultnumbers_screen.dart';
import '../screens/suspense_resultnumbers.dart';
import '../models/numbers_model.dart';

class NumbersScreen extends StatefulWidget {
  @override
  _NumbersScreenState createState() => _NumbersScreenState();
}

class _NumbersScreenState extends State<NumbersScreen> {
  int min = 0;
  int max = 0;
  int count = 1;
  String filter = 'Todos';
  String order = 'Aleatório';
  List<int> results = [];
  bool allowRepeats = false;
  bool showResults = false;
  bool suspenseEnabled = false;
  bool showConfetti = false;
  DateTime drawDate = DateTime.now();
  late NumberDrawModel drawModel;

  final Map<String, String> typeFilters = {
    'all': 'all'.tr(),
    'even_numbers': 'even_numbers'.tr(),
    'odd_numbers': 'odd_numbers'.tr(),
  };

  final Map<String, String> typeOrders = {
    'random': 'random'.tr(),
    'growing': 'growing'.tr(),
    'descending': 'descending'.tr(),
  };

  String _selectedFilter = 'all';
  String _selectedOrders = 'random';


  @override
  void initState() {
    super.initState();
    drawModel = NumberDrawModel(
      min: min,
      max: max,
      count: count,
      allowRepeats: allowRepeats,
      filter: filter,
      order: order,
      suspense: suspenseEnabled,
    );
  }

  Future<void> _generateNumbers() async {
    if (min >= max || count >= (min + max)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('error'.tr()),
          content: Text('fill_number_quantity'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      showResults = false;
      showConfetti = false;
    });

    drawModel.count = count;
    List<int> generatedNumbers = await drawModel.generateNumbers();

    if (suspenseEnabled) {
      drawModel.min = min;
      drawModel.max = max;
      drawModel.count = count;
      drawModel.allowRepeats = allowRepeats;
      drawModel.filter = _selectedFilter;
      drawModel.order = _selectedOrders;
      drawModel.suspense = suspenseEnabled;

      List<int> suspenseResults = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SuspenseResultNumbers(
            onFinish: (numbers) {
              print("Números sorteados: $numbers");
              Navigator.pop(context, numbers);
            },
            initialNumber: min,
            finalNumber: max,
            allowRepeats: allowRepeats,
            quantity: count,
            filter: _selectedFilter,
            order: _selectedOrders,
            drawModel: drawModel, // Passando o mesmo modelo atualizado
          ),
        ),
      );

      generatedNumbers = suspenseResults;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultNumbersScreen(
          results: generatedNumbers,
          suspense: suspenseEnabled,
          drawDate: drawDate,
          finalNumber: max,
          initialNumber: min,
        ),
      ),
    );

    setState(() {
      results = generatedNumbers;
      showResults = true;
      showConfetti = true;
    });
  }


  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                          'number_draw'.tr(),
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
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberInputField('initial_number'.tr(), min, (value) {
                        setState(() {
                          min = int.tryParse(value) ?? min;
                          drawModel.min = min;
                        });
                      }),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberInputField('final_number'.tr(), max, (value) {
                        setState(() {
                          max = int.tryParse(value) ?? max;
                          drawModel.max = max;
                        });
                      }),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildCountSelector(),
                _buildSwitch('allow_repetition'.tr(), allowRepeats, (value) {
                  setState(() {
                    allowRepeats = value;
                    drawModel.allowRepeats = value;
                  });
                }),
                _buildSwitch('enabled_suspense'.tr(), suspenseEnabled, (value) {
                  setState(() {
                    suspenseEnabled = value;
                  });
                }),
                _buildDropdownFilter(),
                SizedBox(height: 16),
                _buildDropdownOrder(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _generateNumbers,
                  child: Text('draw'.tr(),style: TextStyle(fontSize: 20, color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInputField(String label, int value, Function(String) onChanged) {
    return TextField(
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        fillColor: Color(0xCC212121),
        filled: true,
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
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
                    if (count > 1) count--;
                  });
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    count++;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontSize: 18, color: Colors.white)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
    );
  }

  Widget _buildDropdownFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedFilter,
      decoration: InputDecoration(
        labelText: 'filter'.tr(),
        fillColor: Color(0xCC212121),
        filled: true,
        border: OutlineInputBorder(),
      ),
      items: typeFilters.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key, // Mantém a chave ('all', 'even_numbers', 'odd_numbers')
          child: Text(entry.value), // Exibe a tradução
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedFilter = value!;
          drawModel.filter = _selectedFilter;
        });
      },
    );
  }

  Widget _buildDropdownOrder() {
    return DropdownButtonFormField<String>(
      value: _selectedOrders,
      decoration: InputDecoration(
        labelText: 'ordering'.tr(),
        fillColor: Color(0xCC212121),
        filled: true,
        border: OutlineInputBorder(),
      ),
      items: typeOrders.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key, // Mantém a chave ('random', 'growing', 'descending')
          child: Text(entry.value), // Exibe a tradução
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedOrders = value!;
          drawModel.order = _selectedOrders;
        });
      },
    );
  }
}
