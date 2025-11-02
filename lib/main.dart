import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/constants.dart';
import 'widgets/bottom_navbar.dart';
import 'services/notification_service.dart';
import 'services/db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();
  await DBService.instance.resetDatabase();

  runApp(const MoodToMatchaApp());
}

class MoodToMatchaApp extends StatelessWidget {
  const MoodToMatchaApp({super.key});

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
      ),
      home: const BottomNavbar(),
    );
  }
}
