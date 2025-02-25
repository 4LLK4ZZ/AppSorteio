import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/numbers_screen.dart';
import 'screens/names_screen.dart';
import 'screens/teams_screen.dart';

void main() async {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('pt')],
      path: 'assets/lang',
      fallbackLocale: Locale('pt'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (EasyLocalization.of(context) == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'App de Sorteios',
          theme: ThemeData.dark().copyWith(
            primaryColor: Colors.blueGrey[800],
            scaffoldBackgroundColor: Colors.transparent,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                textStyle: TextStyle(color: Colors.white),
              ),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => AppBackground(child: HomeScreen()),
            '/numbers_config': (context) => AppBackground(child: NumbersScreen()),
            '/names_config': (context) => AppBackground(child: NamesScreen()),
            '/teams_config': (context) => AppBackground(child: TeamsScreen()),
          },
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );
      },
    );
  }
}

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/images/background.jpg'),
          fit: BoxFit.cover,
        ),
        gradient: LinearGradient(
          colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
