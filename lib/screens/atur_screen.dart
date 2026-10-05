import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../controllers/akun_controller.dart';
import '../controllers/label_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../controllers/utang_piutang_controller.dart';
import '../controllers/theme_provider.dart';
import '../repositories/database_repository.dart';
import '../services/backup_service.dart';
import 'kelola_akun_screen.dart';
import 'kelola_label_screen.dart';
import 'pencadangan_screen.dart';

final profilProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await ref.read(databaseRepositoryProvider).getProfil();
});

class AturScreen extends ConsumerStatefulWidget {
  const AturScreen({super.key});

  @override
  ConsumerState<AturScreen> createState() => _AturScreenState();
}

class _AturScreenState extends ConsumerState<AturScreen> {
  Future<void> _editProfil(Map<String, dynamic>? currentProfil) async {
    final namaController = TextEditingController(
      text: currentProfil?['nama'] ?? '',
    );
    String? base64Image = currentProfil?['fotoBase64'];

    String autoFormatNama(String input) {
      String res = input.replaceAll(RegExp(r'[\\/:*?"<>|~#%&{}$]'), '');
      res = res.replaceAll(RegExp(r'\s{2,}'), ' ');
      res = res.replaceFirst(RegExp(r'^\.+'), '');
      res = res.trim();
      if (res.isNotEmpty) {
        res = res
            .split(' ')
            .map((word) {
              if (word.isNotEmpty) {
                return word[0].toUpperCase() + word.substring(1);
              }
              return '';
            })
            .join(' ');
      }
      return res;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profil'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final xFile = await picker.pickImage(
                      source: ImageSource.gallery,
                    );

                    if (xFile != null) {
                      final bytes = await xFile.readAsBytes();
                      img.Image? decodedImage = img.decodeImage(bytes);

                      if (decodedImage != null) {
                        img.Image resizedImage = img.copyResize(
                          decodedImage,
                          width: 200,
                        );
                        final compressedBytes = img.encodeJpg(
                          resizedImage,
                          quality: 60,
                        );

                        setStateDialog(() {
                          base64Image = base64Encode(compressedBytes);
                        });
                      }
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: base64Image != null
                        ? MemoryImage(base64Decode(base64Image!))
                        : null,
                    child: base64Image == null
                        ? const Icon(Icons.camera_alt, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: namaController,
                  maxLength: 32,
                  decoration: const InputDecoration(labelText: 'Nama anda'),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final namaFormatted = autoFormatNama(namaController.text);
              await ref
                  .read(databaseRepositoryProvider)
                  .saveProfil(namaFormatted, base64Image);
              ref.invalidate(profilProvider);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final profilAsync = ref.watch(profilProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          // 1. Profil
          profilAsync.when(
            data: (profil) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        profil != null && profil['fotoBase64'] != null
                        ? MemoryImage(base64Decode(profil['fotoBase64']))
                        : null,
                    child: profil == null || profil['fotoBase64'] == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profil?['nama']?.isNotEmpty == true
                              ? profil!['nama']
                              : 'Pengguna',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () => _editProfil(profil),
                          child: const Text(
                            'Edit Profil',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(),

          // 2. Mode Gelap
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Mode Gelap'),
            trailing: Switch(
              value: isDark,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme(value);
              },
            ),
          ),
          const Divider(),

          // 3. Kelola Akun
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Kelola Akun'),
            subtitle: const Text('Tambah, edit, atau hapus akun'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KelolaAkunScreen()),
              );
            },
          ),

          // 4. Kelola Label
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('Kelola Label'),
            subtitle: const Text('Tambah, edit, atau hapus label'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KelolaLabelScreen()),
              );
            },
          ),
          const Divider(),

          // 5. Pencadangan
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.blue),
            title: const Text('Pencadangan'),
            subtitle: const Text('Backup Cloud & Lokal'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PencadanganScreen()),
              );
            },
          ),
          const Divider(),

          // 6 & 7. Ekspor CSV
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Ekspor CSV',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Simpan CSV'),
            subtitle: const Text('Simpan berkas .csv di perangkat'),
            onTap: () async {
              try {
                final backupService = BackupService(
                  ref.read(databaseRepositoryProvider),
                );
                final path = await backupService.simpanCsvKeFolder();

                if (context.mounted && path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV tersimpan')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Bagikan CSV'),
            subtitle: const Text('Bagikan berkas .csv'),
            onTap: () async {
              final backupService = BackupService(
                ref.read(databaseRepositoryProvider),
              );
              await backupService.bagikanCsvLangsung();
            },
          ),
          const Divider(),

          // 8. Tentang Aplikasi
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Tentang Aplikasi'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Finance Tracker App',
                applicationVersion: '1.2.0',
                applicationIcon: const Icon(
                  Icons.account_balance_wallet,
                  size: 58,
                ),
                applicationLegalese: '© 2026 Developer',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Aplikasi pencatatan uang masuk dan keluar dengan arsitektur sinkronisasi Google Drive terenkripsi (Zero-Knowledge).',
                  ),
                ],
              );
            },
          ),
          const Divider(),

          // 9. Reset Seluruh Database
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: const Text(
              'Reset Seluruh Database',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _tampilDialogReset(context, ref),
          ),
        ],
      ),
    );
  }

  void _tampilDialogReset(BuildContext context, WidgetRef ref) {
    bool step1Checked = false;
    final textController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('DANGER ZONE'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tindakan ini akan menghapus permanen seluruh transaksi, utang, akun, dan label. Lanjutkan?',
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Saya paham risiko ini'),
                  value: step1Checked,
                  onChanged: (val) =>
                      setStateDialog(() => step1Checked = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Ketik "RESET" untuk konfirmasi',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setStateDialog(() {}),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (step1Checked && textController.text == 'RESET') {
                await ref.read(databaseRepositoryProvider).resetDatabase();

                ref.invalidate(akunControllerProvider);
                ref.invalidate(labelControllerProvider);
                ref.invalidate(transaksiControllerProvider);
                ref.invalidate(utangPiutangControllerProvider);
                ref.invalidate(profilProvider);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext); // Tutup dialognya
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Database berhasil direset.')),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pastikan kotak dicentang dan mengetik RESET',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}
