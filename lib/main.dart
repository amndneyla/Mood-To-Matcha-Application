import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/constants.dart';
import 'widgets/bottom_navbar.dart';
import 'services/notification_service.dart';
import 'services/db_service.dart';
import 'services/auth_service.dart';
import 'views/login_page.dart';
import 'views/order_history_page.dart';
import 'views/onboarding_page.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  final box = GetStorage();

  await NotificationService().init();
  await DBService.instance.database;

  final auth = AuthService.instance;
  final autoLogin = await auth.tryAutoLogin();

  final seenOnboarding = box.read('seenOnboarding') ?? false;

  runApp(
    MoodToMatchaApp(startAtHome: autoLogin, showOnboarding: !seenOnboarding),
  );
}

class MoodToMatchaApp extends StatelessWidget {
  final bool startAtHome;
  final bool showOnboarding;

  const MoodToMatchaApp({
    super.key,
    required this.startAtHome,
    required this.showOnboarding,
  });

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

      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const BottomNavbar(),
        '/order-history': (_) => const OrderHistoryPage(),
      },

      home: showOnboarding
          ? OnboardingScreen()
          : (startAtHome ? const BottomNavbar() : const LoginPage()),
    );
  }
}
