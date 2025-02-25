import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:sorteiodenumerosenomes/main.dart';
import '../screens/teams_screen.dart';
import '../models/team_model.dart';

class ResultTeamScreen extends StatefulWidget {
  final List<List<String>> teams;
  final TeamModel model = TeamModel();
  final bool enableSuspense;

  ResultTeamScreen({required this.teams, required this.enableSuspense});

  @override
  _ResultTeamScreenState createState() => _ResultTeamScreenState();
}

class _ResultTeamScreenState extends State<ResultTeamScreen>
    with SingleTickerProviderStateMixin {
  ScreenshotController screenshotController = ScreenshotController();
  late AnimationController _animationController;
  late Animation<Color?> _backgroundAnimation;
  late Animation<Alignment> _alignmentAnimation;

  @override
  void initState() {
    super.initState();

    _animationController =
    AnimationController(vsync: this, duration: Duration(seconds: 5))
      ..repeat(reverse: true);

    _backgroundAnimation = ColorTween(
      begin: Colors.blue.shade900.withOpacity(0.2),
      end: Colors.purple.shade900.withOpacity(0.2),
    ).animate(_animationController);

    _alignmentAnimation = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _shareText() {
    String text = 'generated_teams\n\n'.tr();
    for (int i = 0; i < widget.teams.length; i++) {
      text += '${'team'.tr()} ${i + 1}:\n';
      text += widget.teams[i].join(", ") + "\n\n";
    }
    Share.share(text);
  }

  Future<void> _shareImage() async {
    final image = await screenshotController.capture();
    if (image == null) return;

    final directory = await getTemporaryDirectory();
    final imagePath = File("${directory.path}/equipes.png");
    await imagePath.writeAsBytes(image);

    await Share.shareXFiles([XFile(imagePath.path)],
        text: 'generated_teams'.tr());
  }

  Future<void> _sharePDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('generated_teams'.tr(),
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              for (int i = 0; i < widget.teams.length; i++)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue,
                      ),
                      child: pw.Text('team ${i + 1}'.tr(),
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Column(
                      children: widget.teams[i]
                          .map((member) =>
                          pw.Container(
                            padding: pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey),
                            ),
                            child: pw.Text(member,
                                style: pw.TextStyle(fontSize: 16)),
                          ))
                          .toList(),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                ),
            ],
          );
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/equipes.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'generated_teams'.tr());
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _alignmentAnimation.value,
                    end: _alignmentAnimation.value == Alignment.topLeft
                        ? Alignment.bottomRight
                        : Alignment.topLeft,
                    colors: [
                      Colors.blue.withOpacity(0.3),
                      Colors.purple.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Scaffold(
                body: Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _backgroundAnimation.value!,
                        Colors.black.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Screenshot(
                    controller: screenshotController,
                    child: Column(
                      children: [
                        SizedBox(height: 40),
                        Text(
                          'generated_teams'.tr(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                for (int index = 0; index <
                                    widget.teams.length; index++)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .stretch,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(
                                              8),
                                        ),
                                        child: Text(
                                          'team'.tr(namedArgs: {
                                            'number': '${index + 1}'
                                          }),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      ...widget.teams[index].map((member) {
                                        return Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.white54),
                                          ),
                                          child: Text(
                                            member,
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      }).toList(),
                                      SizedBox(height: 12),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Botão de voltar
              Positioned(
                left: 16,
                bottom: 16,
                child: IconButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/teams_config');
                  },
                  icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  iconSize: 36,
                ),
              ),

              // Botão de compartilhar
              Positioned(
                right: 16,
                bottom: 16,
                child: IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(15)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(
                                    Icons.text_fields, color: Colors.white),
                                title: Text('share_text'.tr(),
                                    style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _shareText();
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.image, color: Colors.white),
                                title: Text('share_image'.tr(),
                                    style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _shareImage();
                                },
                              ),
                              ListTile(
                                leading: Icon(
                                    Icons.picture_as_pdf, color: Colors.white),
                                title: Text('share_pdf'.tr(),
                                    style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _sharePDF();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.share, color: Colors.white),
                  iconSize: 36,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}