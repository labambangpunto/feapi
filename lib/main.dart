import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
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
    // ThemeMode di sini sekarang 100% menggunakan material_ui
    final themeMode = ref.watch(themeProvider);
    const seedColor = Colors.blue;

    // Tentukan tema berdasarkan state Riverpod
    M3EThemeData currentThemeData;
    bool isAutoTheming = false;

    if (themeMode == ThemeMode.dark) {
      currentThemeData = M3EThemeData.dark(seedColor: seedColor);
    } else if (themeMode == ThemeMode.light) {
      currentThemeData = M3EThemeData.light(seedColor: seedColor);
    } else {
      // Jika ThemeMode.system, gunakan basis terang namun aktifkan autoTheming
      currentThemeData = M3EThemeData.light(seedColor: seedColor);
      isAutoTheming = true;
    }

    return M3EMaterialApp(
      title: 'Pencatat Keuangan',
      debugShowCheckedModeBanner: false,
      fontFamily: 'SN Pro',
      data: currentThemeData,
      autoTheming: isAutoTheming,
      dynamicColoring: true,
      home: const MainScreen(),
    );
  }
}
