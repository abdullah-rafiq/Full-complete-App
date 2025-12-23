import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'theme_mode_notifier.dart';
import 'app_locale.dart';
import 'routing/app_router.dart';

TextTheme _interWithPoppinsHeadings(TextTheme base) {
  final inter = GoogleFonts.interTextTheme(base);
  return inter.copyWith(
    displayLarge: GoogleFonts.poppins(textStyle: inter.displayLarge),
    displayMedium: GoogleFonts.poppins(textStyle: inter.displayMedium),
    displaySmall: GoogleFonts.poppins(textStyle: inter.displaySmall),
    headlineLarge: GoogleFonts.poppins(textStyle: inter.headlineLarge),
    headlineMedium: GoogleFonts.poppins(textStyle: inter.headlineMedium),
    headlineSmall: GoogleFonts.poppins(textStyle: inter.headlineSmall),
    titleLarge: GoogleFonts.poppins(textStyle: inter.titleLarge),
    titleMedium: GoogleFonts.poppins(textStyle: inter.titleMedium),
    titleSmall: GoogleFonts.poppins(textStyle: inter.titleSmall),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }
  await AppTheme.init();
  await AppLocale.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: AppLocale.locale,
          builder: (context, locale, child) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Assist',
              themeMode: themeMode,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('ur')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: child!,
                );
              },
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
                textTheme: _interWithPoppinsHeadings(
                  ThemeData(brightness: Brightness.light).textTheme,
                ),
                primaryTextTheme: _interWithPoppinsHeadings(
                  ThemeData(brightness: Brightness.light).textTheme,
                ),
                scaffoldBackgroundColor: const Color(0xFFF6FBFF),
                appBarTheme: const AppBarTheme(
                  elevation: 4,
                  backgroundColor: Color(0xFF29B6F6),
                  foregroundColor: Colors.white,
                ),
                cardColor: Colors.white,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
                textTheme: _interWithPoppinsHeadings(
                  ThemeData(brightness: Brightness.dark).textTheme,
                ),
                primaryTextTheme: _interWithPoppinsHeadings(
                  ThemeData(brightness: Brightness.dark).textTheme,
                ),
                scaffoldBackgroundColor: const Color(0xFF121212),
                appBarTheme: AppBarTheme(
                  elevation: 4,
                  backgroundColor: ColorScheme.fromSeed(
                    seedColor: Colors.blue,
                    brightness: Brightness.dark,
                  ).primary,
                  foregroundColor: Colors.white,
                ),
                cardColor: const Color(0xFF1E1E1E),
              ),
              routerConfig: AppRouter.router,
            );
          },
        );
      },
    );
  }
}
