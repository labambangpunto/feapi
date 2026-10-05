import 'dart:io';

import 'package:material_ui/material_ui.dart';
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
    // Pantau perubahan ThemeMode (light, dark, atau system) dari state
    final themeMode = ref.watch(themeProvider);
    const seedColor = Colors.blue;

    return MaterialApp(
      title: 'Pencatat Keuangan',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: seedColor,
        brightness: Brightness.light,
        fontFamily: 'SN Pro',
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: seedColor,
        brightness: Brightness.dark,
        fontFamily: 'SN Pro',
      ),
      home: const MainScreen(),
    );
  }
}
