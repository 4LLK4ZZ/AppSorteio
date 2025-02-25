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
    'problem': 'problem'.tr()
  };

  final Map<String, String> categoryOptions = {
    'name_draw': 'name_draw'.tr(),
    'number_draw': 'number_draw'.tr(),
    'generate_teams': 'generate_teams'.tr(),
  };

  String _selectedType = 'suggestion';
  String _selectedCategory = 'name_draw';

  Future<void> _sendEmail() async {
    String username = 'alcidesaugusto0011@gmail.com'; // Seu e-mail
    String password = 'gaqf bati wdyw zscv'; // Senha de Aplicativo

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Suporte do App')
      ..recipients.add('alcidesaugusto0011@gmail.com')
      ..subject = '[$_selectedType] $_selectedCategory'
      ..text = '''
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
        SnackBar(content: Text('success_ticket'.tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_ticket $e'.tr())),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (!categoryOptions.containsKey(_selectedCategory)) {
      _selectedCategory = categoryOptions.keys.first; // Garante um valor válido
    }
  }


  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        body: Padding(
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
                decoration:
                InputDecoration(
                    labelText: 'name'.tr(),
                  fillColor: Color(0xCC212121),
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration:
                InputDecoration(
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
                decoration: InputDecoration(labelText: 'details'.tr(),
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
                    backgroundColor: Colors.green, // Botão verde
                  ),
                  child: Text('send'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
