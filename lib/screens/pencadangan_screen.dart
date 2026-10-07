import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/akun_controller.dart';
import '../controllers/label_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../controllers/utang_piutang_controller.dart';
import '../repositories/database_repository.dart';
import '../services/backup_service.dart';
import '../services/google_drive_service.dart';
import 'atur_screen.dart'; // Digunakan untuk memanggil profilProvider

class PencadanganScreen extends ConsumerStatefulWidget {
  const PencadanganScreen({super.key});

  @override
  ConsumerState<PencadanganScreen> createState() => _PencadanganScreenState();
}

class _PencadanganScreenState extends ConsumerState<PencadanganScreen> {
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

  Future<String?> _tampilDialogPassword(BuildContext context, String judul) {
    final passController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(judul),
        content: TextField(
          controller: passController,
          obscureText: true,
          maxLength: 32,
          decoration: const InputDecoration(
            labelText: 'Password Enkripsi',
            counterText: '',
            helperText: 'Minimal 6 karakter untuk keamanan AES',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (passController.text.length >= 6) {
                Navigator.pop(dialogContext, passController.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pencadangan Data')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sinkronisasi Cloud',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
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
                  Navigator.pop(context); // Tutup loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup ke Google Drive berhasil'),
                    ),
                  );
                }
              } catch (e) {
                await _checkDriveSession();
                if (context.mounted) {
                  Navigator.pop(context); // Tutup loading
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
                  Navigator.pop(context); // Tutup loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restore dari Google Drive berhasil'),
                    ),
                  );
                }
              } catch (e) {
                await _checkDriveSession();
                if (context.mounted) {
                  Navigator.pop(context); // Tutup loading
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
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext); // Tutup dialog
                        await GoogleDriveService().logout();
                        await _checkDriveSession();

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
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Text(
              'Backup Data Lokal (.enc)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
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
        ],
      ),
    );
  }
}
