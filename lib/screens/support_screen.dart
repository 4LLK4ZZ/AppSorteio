import 'dart:math';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:sorteiodenumerosenomes/main.dart';

class SupportScreen extends StatefulWidget {
  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final Map<String, String> typeOptions = {
    'suggestion': 'suggestion'.tr(),
    'problem': 'problem'.tr(),
  };

  final Map<String, String> categoryOptions = {
    'name_draw': 'name_draw'.tr(),
    'number_draw': 'number_draw'.tr(),
    'generate_teams': 'generate_teams'.tr(),
  };

  String _selectedType = 'suggestion';
  String _selectedCategory = 'name_draw';

  /// Gera um número de ticket único
  String _generateTicketNumber() {
    final now = DateTime.now();
    final datePart = DateFormat('yyyyMMdd-HHmmss').format(now);
    final randomPart = Random().nextInt(9000) + 1000; // Número aleatório de 4 dígitos
    return 'TICKET-$datePart-$randomPart';
  }

  Future<void> _sendEmail() async {
    String username = 'seu_email';
    String password = 'sua_senha_de_app';

    final smtpServer = gmail(username, password);
    final ticketNumber = _generateTicketNumber();

    final message = Message()
      ..from = Address(username, 'Suporte do App')
      ..recipients.add('alcidesaugusto0011@gmail.com')
      ..subject = '[$_selectedType] $_selectedCategory - $ticketNumber'
      ..text = '''
Número do Ticket: $ticketNumber

Nome: ${_nameController.text}
Email: ${_emailController.text}

Tipo: $_selectedType
Categoria: $_selectedCategory

Detalhes:
${_messageController.text}
''';

    try {
      await send(message, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('success_ticket'.tr() + '\nNúmero do Ticket: $ticketNumber'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_ticket'.tr() + ' $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (!categoryOptions.containsKey(_selectedCategory)) {
      _selectedCategory = categoryOptions.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Evita que o teclado empurre a tela
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'support'.tr(),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'name'.tr(),
                    fillColor: Color(0xCC212121),
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'email'.tr(),
                    fillColor: Color(0xCC212121),
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'type'.tr(),
                    fillColor: Color(0xCC212121),
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                  items: typeOptions.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'category'.tr(),
                    fillColor: Color(0xCC212121),
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                  items: categoryOptions.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'details'.tr(),
                    fillColor: Color(0xCC212121),
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _sendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('send'.tr()),
                  ),
                ),
                SizedBox(height: 20), // Espaço extra para não cortar o botão ao abrir o teclado
              ],
            ),
          ),
        ),
      ),
    );
  }
}
