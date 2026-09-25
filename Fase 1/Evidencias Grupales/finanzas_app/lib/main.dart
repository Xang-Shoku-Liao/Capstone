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
        primaryColor: const Color(0xFF028090),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF028090),
          primary: const Color(0xFF028090),
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
