import 'package:flutter/material.dart';
import 'numbers_screen.dart';
import 'names_screen.dart';
import 'teams_screen.dart';
import 'my_lists.dart';
import 'support_screen.dart';
import '../widgets/menu_button.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;
  List<Map<String, dynamic>> savedLists = [];
  bool isMenuOpen = false;
  bool isLanguageOverlayOpen = false;
  String selectedLanguage = 'pt';

  void toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  void navigateTo(Widget page) {
    setState(() {
      isMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void showLanguageOverlay() {
    setState(() {
      isLanguageOverlayOpen = true;
    });
  }

  void closeLanguageOverlay() {
    setState(() {
      isLanguageOverlayOpen = false;
    });
  }

  void changeLanguage(String languageCode) {
    Locale newLocale = Locale(languageCode);
    context.setLocale(newLocale);
    setState(() {
      selectedLanguage = languageCode;
      isLanguageOverlayOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/images/logo.png',
                  height: 150,
                ),
                SizedBox(height: 5),
                Center(
                  child: Text(
                    'what_to_draw'.tr(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 40),

                MenuButton(
                  label: 'numbers'.tr(),
                  icon: Icons.numbers_sharp,
                  onTap: () => navigateTo(NumbersScreen()),
                ),
                MenuButton(
                  label: 'names'.tr(),
                  icon: Icons.person,
                  onTap: () => navigateTo(NamesScreen()),
                ),
                MenuButton(
                  label: 'teams'.tr(),
                  icon: Icons.group,
                  onTap: () => navigateTo(TeamsScreen()),
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.menu),
              color: Colors.white,
              iconSize: 32,
              onPressed: toggleMenu,
            ),
          ),
          if (isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: toggleMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMenuItem(
                            'my_lists'.tr(),
                            Icons.list,
                                () => navigateTo(
                                MyListScreen(savedLists: savedLists))),
                        SizedBox(height: 20),
                        Text(
                          'settings'.tr(),
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        _buildMenuItem('language'.tr(), Icons.language,
                            showLanguageOverlay),
                        _buildMenuItem('support'.tr(), Icons.support,
                                () => navigateTo(SupportScreen())),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (isLanguageOverlayOpen) _buildLanguageOverlay(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.blueGrey[700],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blueGrey[500]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey[800],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(
                    'Português BR', 'lib/assets/images/brazil_flag.png', 'pt'),
                _buildLanguageOption(
                    'Inglês', 'lib/assets/images/uk_flag.png', 'en'),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: closeLanguageOverlay,
                  child: Text(
                    'close_window'.tr(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String title, String assetPath, String langCode) {
    return GestureDetector(
      onTap: () => changeLanguage(langCode),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selectedLanguage == langCode
              ? Colors.blueGrey[600]
              : Colors.blueGrey[700],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blueGrey[500]!),
        ),
        child: Row(
          children: [
            Image.asset(assetPath, width: 40),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            Spacer(),
            if (selectedLanguage == langCode)
              Icon(Icons.check, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
