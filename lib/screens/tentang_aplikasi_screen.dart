import 'package:material_ui/material_ui.dart';

class TentangAplikasiScreen extends StatelessWidget {
  const TentangAplikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Daftar dependensi berdasarkan pubspec.yaml
    final List<String> dependencies = [
      'cupertino_icons',
      'material_3_expressive',
      'sqflite_common_ffi',
      'flutter_riverpod',
      'csv',
      'path_provider',
      'share_plus',
      'encrypt',
      'file_picker',
      'fl_chart',
      'google_sign_in',
      'googleapis',
      'googleapis_auth',
      'http',
      'path',
      'sqflite',
      'shared_preferences',
      'image_picker',
      'flutter_secure_storage',
      'image',
      'material_ui',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: Center(
        // Tambahkan Center
        child: SingleChildScrollView(
          // Tambahkan scroll horizontal
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            // Tambahkan batas lebar minimum
            width: MediaQuery.of(context).size.width < 320
                ? 320
                : MediaQuery.of(context).size.width,
            child: ListView(
              // ListView yang sudah ada
              shrinkWrap:
                  true, // Pastikan ListView tidak mengambil tinggi tak terbatas
              padding: const EdgeInsets.all(16.0),
              children: [
                const SizedBox(height: 16),
                Image.asset('assets/icon/logo.png', width: 80, height: 80),
                const SizedBox(height: 16),
                const Text(
                  'Finance Tracker App',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                const SizedBox(height: 32),
                const Text(
                  'Aplikasi pencatatan uang masuk dan keluar dengan arsitektur sinkronisasi Google Drive terenkripsi (Zero-Knowledge).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Paket & Dependensi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: dependencies
                      .map(
                        (dep) => Chip(
                          label: Text(
                            dep,
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Center(
                  child: FilledButton.icon(
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Finance Tracker App',
                      );
                    },
                    icon: const Icon(Icons.description),
                    label: const Text('Lisensi Perangkat Lunak'),
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  '© 2026 Developer',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
