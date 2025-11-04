import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/constants.dart';
import 'widgets/bottom_navbar.dart';
import 'services/notification_service.dart';
import 'services/db_service.dart';
import 'services/auth_service.dart';
import 'views/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();
  await DBService.instance.database;

  final auth = AuthService.instance;
  final autoLogin = await auth.tryAutoLogin();

  runApp(MoodToMatchaApp(startAtHome: autoLogin));
}

class MoodToMatchaApp extends StatelessWidget {
  final bool startAtHome;
  const MoodToMatchaApp({super.key, required this.startAtHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBackgroundColor,
        primaryColor: kPrimaryColor,
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: kTextColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
      home: startAtHome ? const BottomNavbar() : const LoginPage(),
    );
  }
}
