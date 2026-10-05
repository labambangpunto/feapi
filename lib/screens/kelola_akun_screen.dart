import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/akun_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../controllers/utang_piutang_controller.dart';
import '../models/akun_model.dart';

class KelolaAkunScreen extends ConsumerWidget {
  const KelolaAkunScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final akunState = ref.watch(akunControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Akun')),
      body: akunState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (akunList) {
          if (akunList.isEmpty) {
            return const Center(child: Text('Belum ada akun'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: akunList.length,
            itemBuilder: (context, index) {
              final akun = akunList[index];
              final isDibekukan = akun.isDibekukan;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      akun.nama,
                      style: TextStyle(
                        decoration: isDibekukan
                            ? TextDecoration.lineThrough
                            : null,
                        color: isDibekukan ? Colors.grey : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: isDibekukan
                        ? const Text(
                            'Dibekukan',
                            style: TextStyle(color: Colors.red),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isDibekukan)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _tampilFormEditAkun(context, ref, akun),
                          ),
                        IconButton(
                          icon: Icon(
                            isDibekukan ? Icons.restore : Icons.delete,
                            color: isDibekukan ? Colors.green : Colors.red,
                          ),
                          onPressed: () {
                            if (isDibekukan) {
                              _pulihkanAkun(context, ref, akun);
                            } else {
                              _cekDanHapusAtauBekukan(context, ref, akun);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tampilFormTambahAkun(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _cekDanHapusAtauBekukan(
    BuildContext context,
    WidgetRef ref,
    AkunModel akun,
  ) {
    final transaksiList = ref.read(transaksiControllerProvider).value ?? [];
    final utangList = ref.read(utangPiutangControllerProvider).value ?? [];

    final isDigunakanDiTransaksi = transaksiList.any(
      (t) => t.akunSumberId == akun.id || t.akunTujuanId == akun.id,
    );
    final isDigunakanDiUtang = utangList.any((u) => u.akunId == akun.id);

    if (isDigunakanDiTransaksi || isDigunakanDiUtang) {
      _tampilDialogBekukanAkun(context, ref, akun);
    } else {
      _tampilDialogHapusAkun(context, ref, akun);
    }
  }

  void _tampilDialogBekukanAkun(
    BuildContext context,
    WidgetRef ref,
    AkunModel akun,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Akun Sedang Digunakan'),
        content: Text(
          'Akun "${akun.nama}" tidak bisa dihapus karena terikat pada transaksi atau utang/piutang.\n\nApakah Anda ingin membekukannya? (Akun tidak akan muncul di form input baru)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final akunDibekukan = akun.copyWith(isDibekukan: true);
              ref
                  .read(akunControllerProvider.notifier)
                  .updateAkun(akunDibekukan);
              Navigator.pop(dialogContext);
            },
            child: const Text('Bekukan'),
          ),
        ],
      ),
    );
  }

  void _pulihkanAkun(BuildContext context, WidgetRef ref, AkunModel akun) {
    final akunDipulihkan = akun.copyWith(isDibekukan: false);
    ref.read(akunControllerProvider.notifier).updateAkun(akunDipulihkan);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Akun berhasil dipulihkan')));
  }

  void _tampilFormTambahAkun(BuildContext context, WidgetRef ref) {
    final namaController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (contextState, setStateDialog) => AlertDialog(
          title: const Text('Tambah Akun Baru'),
          content: TextField(
            controller: namaController,
            decoration: const InputDecoration(labelText: 'Nama akun'),
            onChanged: (val) => setStateDialog(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: (namaController.text.trim().isNotEmpty)
                  ? () {
                      final namaBaru = _autoFormatNama(namaController.text);
                      if (namaBaru.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nama tidak valid')),
                        );
                        return;
                      }

                      final currentAkun =
                          ref.read(akunControllerProvider).value ?? [];
                      final isDuplicate = currentAkun.any(
                        (a) => a.nama.toLowerCase() == namaBaru.toLowerCase(),
                      );

                      if (isDuplicate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nama akun sudah digunakan'),
                          ),
                        );
                        return;
                      }

                      final akun = AkunModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nama: namaBaru,
                        isDibekukan: false,
                      );
                      ref
                          .read(akunControllerProvider.notifier)
                          .tambahAkun(akun);
                      Navigator.pop(dialogContext);
                    }
                  : null,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _tampilFormEditAkun(
    BuildContext context,
    WidgetRef ref,
    AkunModel akunLama,
  ) {
    final namaController = TextEditingController(text: akunLama.nama);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Akun'),
        content: TextField(
          controller: namaController,
          decoration: const InputDecoration(labelText: 'Nama akun'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final namaEdit = _autoFormatNama(namaController.text);
              if (namaEdit.isEmpty) return;

              final currentAkun = ref.read(akunControllerProvider).value ?? [];
              final isDuplicate = currentAkun.any(
                (a) =>
                    a.id != akunLama.id &&
                    a.nama.toLowerCase() == namaEdit.toLowerCase(),
              );

              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama akun sudah digunakan')),
                );
                return;
              }

              final akunUpdate = akunLama.copyWith(nama: namaEdit);
              ref.read(akunControllerProvider.notifier).updateAkun(akunUpdate);
              Navigator.pop(dialogContext);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _tampilDialogHapusAkun(
    BuildContext context,
    WidgetRef ref,
    AkunModel akun,
  ) {
    bool isChecked = false;
    final textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (contextState, setStateDialog) {
          return AlertDialog(
            title: const Text('Hapus Akun'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Apakah Anda yakin ingin menghapus permanen akun "${akun.nama}"?',
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text(
                    'Saya paham akun ini akan dihapus permanen',
                  ),
                  value: isChecked,
                  onChanged: (val) =>
                      setStateDialog(() => isChecked = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Ketik "HAPUS" untuk konfirmasi',
                  ),
                  onChanged: (val) => setStateDialog(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: (isChecked && textController.text == 'HAPUS')
                    ? () {
                        ref
                            .read(akunControllerProvider.notifier)
                            .hapusAkun(akun.id);
                        Navigator.pop(dialogContext);
                      }
                    : null,
                child: const Text('Hapus'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _autoFormatNama(String input) {
    String res = input.replaceAll(RegExp(r'[\\/:*?"<>|~#%&{}$]'), '');
    res = res.replaceAll(RegExp(r'\s{2,}'), ' ');
    res = res.replaceFirst(RegExp(r'^\.+'), '');
    return res.trim();
  }
}
