import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/home_screen.dart';

void main() {
  // sqflite funciona de forma nativa en Android/iOS/macOS, pero Windows y
  // Linux necesitan la implementación FFI. Sin esto la primera consulta a la
  // base de datos queda sin un plugin disponible en escritorio.
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const FinanzasApp());
}

class FinanzasApp extends StatelessWidget {
  const FinanzasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Finanzas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF31D9D0),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF31D9D0),
          secondary: Color(0xFF42D392),
          surface: Color(0xFF141F26),
          error: Color(0xFFFF8F87),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1014),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1014),
          foregroundColor: Color(0xFFF2FFFC),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF101A20),
          indicatorColor: Color(0x2631D9D0),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          iconTheme: WidgetStatePropertyAll(
            IconThemeData(color: Color(0xFF9CAEB0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF141F26),
          hintStyle: const TextStyle(color: Color(0xFF8EA2A5)),
          labelStyle: const TextStyle(color: Color(0xFF8EA2A5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF22333A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF31D9D0), width: 1.4),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF18242B),
          titleTextStyle: TextStyle(
            color: Color(0xFFF2FFFC),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: TextStyle(color: Color(0xFFC0CFD0)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF141F26),
          surfaceTintColor: Colors.transparent,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
