import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

import 'screens/main_screen.dart';
import 'controllers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi FFI untuk platform desktop (Windows/Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Pencatat Keuangan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SN Pro', // Menerapkan font kustom secara global
        colorSchemeSeed: Colors.blue, // Sesuaikan warna dasar aplikasi
        // Terapkan ekstensi textTheme atau pengaturan spesifik dari material_3_expressive di sini
        // textTheme: ExpressiveTextTheme(), // (Contoh jika package menyediakan class ini)
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SN Pro',
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      themeMode: themeMode,
      home: const MainScreen(),
    );
  }
}
