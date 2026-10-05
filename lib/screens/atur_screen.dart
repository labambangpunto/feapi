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
import '../services/google_drive_service.dart';
import 'kelola_akun_screen.dart';
import 'kelola_label_screen.dart';

final profilProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await ref.read(databaseRepositoryProvider).getProfil();
});

class AturScreen extends ConsumerStatefulWidget {
  const AturScreen({super.key});

  @override
  ConsumerState<AturScreen> createState() => _AturScreenState();
}

class _AturScreenState extends ConsumerState<AturScreen> {
  bool _isDriveSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkDriveSession();
  }

  Future<void> _checkDriveSession() async {
    final signedIn = await GoogleDriveService().hasSession();
    if (mounted) {
      setState(() => _isDriveSignedIn = signedIn);
    }
  }

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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sinkronisasi Cloud',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                if (!_isDriveSignedIn)
                  const Text(
                    'Tidak ada sesi aktif',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.cloud_upload, color: Colors.blue),
            title: const Text('Backup ke Google Drive'),
            subtitle: const Text('Timpa data terenkripsi di cloud'),
            onTap: () async {
              final password = await _tampilDialogPassword(
                context,
                'Buat Password Backup Drive',
              );
              if (password == null) return;

              if (!context.mounted) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
              try {
                final backupService = BackupService(
                  ref.read(databaseRepositoryProvider),
                );
                final driveService = GoogleDriveService();

                final encryptedData = await backupService.generateEncryptedJson(
                  password,
                );
                await driveService.backupDatabase(encryptedData);

                await _checkDriveSession();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup ke Google Drive berhasil'),
                    ),
                  );
                }
              } catch (e) {
                await _checkDriveSession();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Gagal backup: $e')));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download, color: Colors.blue),
            title: const Text('Restore dari Google Drive'),
            subtitle: const Text('Timpa data lokal dengan data cloud'),
            onTap: () async {
              final password = await _tampilDialogPassword(
                context,
                'Masukkan Password Restore Drive',
              );
              if (password == null) return;

              if (!context.mounted) return;

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );
              try {
                final backupService = BackupService(
                  ref.read(databaseRepositoryProvider),
                );
                final driveService = GoogleDriveService();

                final encryptedData = await driveService.restoreDatabase();
                await backupService.restoreFromEncryptedString(
                  encryptedData,
                  password,
                );

                ref.invalidate(akunControllerProvider);
                ref.invalidate(labelControllerProvider);
                ref.invalidate(transaksiControllerProvider);
                ref.invalidate(utangPiutangControllerProvider);
                ref.invalidate(profilProvider);

                await _checkDriveSession();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restore dari Google Drive berhasil'),
                    ),
                  );
                }
              } catch (e) {
                await _checkDriveSession();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Gagal restore: $e')));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text('Logout Google Drive'),
            onTap: () async {
              if (!_isDriveSignedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tidak ada sesi untuk logout')),
                );
                return;
              }

              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text(
                    'Apakah Anda yakin ingin memutuskan akses dari Google Drive?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext); // Tutup dialogContext

                        await GoogleDriveService().logout();
                        await _checkDriveSession();

                        // context di bawah ini sekarang aman merujuk pada State layar utama
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sesi Google Drive diakhiri'),
                            ),
                          );
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Backup Data Lokal (.enc)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('Backup lokal'),
            subtitle: const Text('Simpan berkas .enc di perangkat'),
            onTap: () async {
              final password = await _tampilDialogPassword(
                context,
                'Buat Password Backup',
              );
              if (password != null) {
                try {
                  final backupService = BackupService(
                    ref.read(databaseRepositoryProvider),
                  );
                  await backupService.simpanBackupKeFolder(password);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Berhasil tersimpan')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan: $e')),
                    );
                  }
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Bagikan Backup'),
            subtitle: const Text('Bagikan berkas .enc'),
            onTap: () async {
              final password = await _tampilDialogPassword(
                context,
                'Buat Password Backup',
              );
              if (password != null) {
                final backupService = BackupService(
                  ref.read(databaseRepositoryProvider),
                );
                await backupService.bagikanBackupLangsung(password);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: const Text('Restore Lokal'),
            subtitle: const Text('Cari berkas .enc'),
            onTap: () async {
              final password = await _tampilDialogPassword(
                context,
                'Masukkan Password Backup',
              );
              if (password != null) {
                try {
                  final backupService = BackupService(
                    ref.read(databaseRepositoryProvider),
                  );
                  await backupService.restoreJsonLokal(password);

                  ref.invalidate(akunControllerProvider);
                  ref.invalidate(labelControllerProvider);
                  ref.invalidate(transaksiControllerProvider);
                  ref.invalidate(utangPiutangControllerProvider);
                  ref.invalidate(profilProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data berhasil dipulihkan.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Gagal memulihkan: Password salah atau file korup',
                        ),
                      ),
                    );
                  }
                }
              }
            },
          ),

          const Divider(),
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
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
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
                  // Munculkan snackbar pada konteks layar utama
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

  Future<String?> _tampilDialogPassword(BuildContext context, String judul) {
    final passController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(judul),
        content: TextField(
          controller: passController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password Enkripsi',
            helperText: 'Minimal 6 karakter untuk keamanan AES',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (passController.text.length >= 6) {
                Navigator.pop(context, passController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password terlalu pendek')),
                );
              }
            },
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }
}
