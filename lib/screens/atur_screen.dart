import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
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
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Mode Gelap'),
            value: isDark,
            onChanged: (value) {
              ref.read(themeProvider.notifier).state = value
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
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
            subtitle: const Text('Simpan data terenkripsi ke cloud'),
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

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text(
                    'Apakah Anda yakin ingin memutuskan akses dari Google Drive?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await GoogleDriveService().logout();
                await _checkDriveSession();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesi Google Drive diakhiri')),
                  );
                }
              }
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
            title: const Text('Simpan Otomatis ke Folder'),
            subtitle: const Text('Feapi/backup/'),
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
                      const SnackBar(
                        content: Text('Tersimpan di Documents/Feapi/backup/'),
                      ),
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
            title: const Text('Bagikan File Backup'),
            subtitle: const Text(
              'Bagikan file .enc tanpa menyimpan ke perangkat',
            ),
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
            title: const Text('Restore Data Lokal (.enc)'),
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
            title: const Text('Simpan ke Folder Pilihan'),
            subtitle: const Text('Pilih sendiri lokasi penyimpanan .csv'),
            onTap: () async {
              try {
                final backupService = BackupService(
                  ref.read(databaseRepositoryProvider),
                );
                final path = await backupService.simpanCsvKeFolder();

                if (context.mounted && path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('CSV tersimpan di:\n$path')),
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
            subtitle: const Text(
              'Bagikan file .csv tanpa menyimpan ke perangkat',
            ),
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
                applicationName: 'Feapi App',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.account_balance_wallet,
                  size: 48,
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'DANGER ZONE',
                style: TextStyle(color: Colors.red),
              ),
              content: Column(
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
                        setState(() => step1Checked = val ?? false),
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
                    onChanged: (val) => setState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: (step1Checked && textController.text == 'RESET')
                      ? () async {
                          await ref
                              .read(databaseRepositoryProvider)
                              .resetDatabase();

                          ref.invalidate(akunControllerProvider);
                          ref.invalidate(labelControllerProvider);
                          ref.invalidate(transaksiControllerProvider);
                          ref.invalidate(utangPiutangControllerProvider);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Database berhasil direset.'),
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text(
                    'Hapus Semua',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
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
          ElevatedButton(
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
