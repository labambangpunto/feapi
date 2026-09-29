import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/akun_controller.dart';
import '../controllers/label_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../controllers/utang_piutang_controller.dart';
import '../controllers/theme_provider.dart';
import '../models/akun_model.dart';
import '../models/label_model.dart';
import '../repositories/database_repository.dart';
import '../services/backup_service.dart';

class AturScreen extends ConsumerWidget {
  const AturScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Kelola Akun'),
            subtitle: const Text('Buat akun baru dan isi saldo awal'),
            onTap: () => _tampilFormTambahAkun(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('Kelola Label'),
            subtitle: const Text('Buat label baru'),
            onTap: () => _tampilFormTambahLabel(context, ref),
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
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Backup Data (Enkripsi JSON)'),
            onTap: () async {
              final backupService = BackupService(
                ref.read(databaseRepositoryProvider),
              );
              await backupService.backupJsonLokal('PasswordRahasia123');
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Restore Data (.enc)'),
            onTap: () async {
              try {
                final backupService = BackupService(
                  ref.read(databaseRepositoryProvider),
                );
                await backupService.restoreJsonLokal('PasswordRahasia123');

                ref.invalidate(akunControllerProvider);
                ref.invalidate(labelControllerProvider);
                ref.invalidate(transaksiControllerProvider);
                ref.invalidate(utangPiutangControllerProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data berhasil dipulihkan.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal memulihkan: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_view),
            title: const Text('Ekspor CSV'),
            onTap: () async {
              final backupService = BackupService(
                ref.read(databaseRepositoryProvider),
              );
              await backupService.eksporCsv();
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
                  // Verifikasi 1: Checkbox
                  CheckboxListTile(
                    title: const Text('Saya paham risiko ini'),
                    value: step1Checked,
                    onChanged: (val) =>
                        setState(() => step1Checked = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  // Verifikasi 2: Ketik teks
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Ketik "RESET" untuk konfirmasi',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() {}), // Refresh tombol hapus
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
                          // 1. Eksekusi reset di database
                          await ref
                              .read(databaseRepositoryProvider)
                              .resetDatabase();

                          // 2. Refresh (invalidate) semua state controller Riverpod agar UI menjadi kosong
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
                      : null, // Tombol disable jika dua verifikasi belum terpenuhi
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

  void _tampilFormTambahAkun(BuildContext context, WidgetRef ref) {
    final namaController = TextEditingController();
    final saldoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Form Tambah Akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama akun baru'),
            ),
            TextField(
              controller: saldoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Saldo awal',
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (namaController.text.isEmpty) return;
              final akun = AkunModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                nama: namaController.text,
                saldoAwal:
                    double.tryParse(saldoController.text.replaceAll('.', '')) ??
                    0,
              );
              ref.read(akunControllerProvider.notifier).tambahAkun(akun);
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _tampilFormTambahLabel(BuildContext context, WidgetRef ref) {
    final namaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Form Tambah Label'),
        content: TextField(
          controller: namaController,
          decoration: const InputDecoration(labelText: 'Nama label baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (namaController.text.isEmpty) return;
              final label = LabelModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                nama: namaController.text,
              );
              ref.read(labelControllerProvider.notifier).tambahLabel(label);
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
