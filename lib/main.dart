import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landingPage.dart';
import 'login.dart';
import 'register.dart';
import 'dashboard.dart';
import 'tambahJajanan.dart';
import 'profile.dart';
import 'favorite.dart';
import 'myReview.dart';
import 'detailJajanan.dart';
import 'jajananku.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snack Hunt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      initialRoute: '/landing',
      routes: {
        '/landing': (context) => LandingPage(
          onComplete: () {
            // Navigate to dashboard after landing page animation completes
            Navigator.of(context).pushReplacementNamed('/dashboard');
          },
        ),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/tambahJajanan': (context) => const AddSnackPage(),
        '/profile': (context) => const ProfilePage(),
        '/favorite': (context) => const FavoritePage(),
        '/myReview': (context) => const MyReviewPage(),
        '/detailJajanan': (context) => const FoodDetailPage(),
        '/jajananku': (context) => const JajananKu(),
      },
    );
  }
}