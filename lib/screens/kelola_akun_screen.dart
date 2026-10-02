import 'package:flutter/material.dart';
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
            itemCount: akunList.length,
            itemBuilder: (context, index) {
              final akun = akunList[index];
              final isDibekukan = akun
                  .isDibekukan; // Membutuhkan properti isDibekukan di AkunModel

              return ListTile(
                title: Text(
                  akun.nama,
                  style: TextStyle(
                    decoration: isDibekukan ? TextDecoration.lineThrough : null,
                    color: isDibekukan ? Colors.grey : Colors.black,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Akun Sedang Digunakan',
          style: TextStyle(color: Colors.orange),
        ),
        content: Text(
          'Akun "${akun.nama}" tidak bisa dihapus karena terikat pada transaksi atau utang/piutang.\n\nApakah Anda ingin membekukannya? (Akun tidak akan muncul di form input baru)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              // Membutuhkan metode copyWith di AkunModel
              final akunDibekukan = akun.copyWith(isDibekukan: true);
              ref
                  .read(akunControllerProvider.notifier)
                  .updateAkun(akunDibekukan);
              Navigator.pop(context);
            },
            child: const Text('Bekukan', style: TextStyle(color: Colors.white)),
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
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Akun Baru'),
          content: TextField(
            controller: namaController,
            maxLength: 16, // Ubah dari 32 menjadi 16
            decoration: const InputDecoration(labelText: 'Nama akun'),
            onChanged: (val) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: (namaController.text.trim().isNotEmpty)
                  ? () {
                      // Terapkan auto-format pada input mentah
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
                        nama: namaBaru, // Gunakan nama yang telah diformat
                        isDibekukan: false,
                      );
                      ref
                          .read(akunControllerProvider.notifier)
                          .tambahAkun(akun);
                      Navigator.pop(context);
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Akun'),
        content: TextField(
          controller: namaController,
          maxLength: 16, // Tambahkan baris ini
          decoration: const InputDecoration(labelText: 'Nama akun'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Terapkan auto-format pada input mentah
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

              final akunUpdate = akunLama.copyWith(
                nama: namaEdit,
              ); // Gunakan nama yang telah diformat
              ref.read(akunControllerProvider.notifier).updateAkun(akunUpdate);
              Navigator.pop(context);
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
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Hapus Akun',
                style: TextStyle(color: Colors.red),
              ),
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
                        setState(() => isChecked = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Ketik "HAPUS" untuk konfirmasi',
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
                  onPressed: (isChecked && textController.text == 'HAPUS')
                      ? () {
                          ref
                              .read(akunControllerProvider.notifier)
                              .hapusAkun(akun.id);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text(
                    'Hapus',
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

  String _autoFormatNama(String input) {
    // 4. Hapus karakter terlarang
    String res = input.replaceAll(RegExp(r'[\\/:*?"<>|~#%&{}$]'), '');
    // 3. Ganti spasi ganda (atau lebih) menjadi spasi tunggal
    res = res.replaceAll(RegExp(r'\s{2,}'), ' ');
    // 2. Hapus titik jika berada di paling awal nama
    res = res.replaceFirst(RegExp(r'^\.+'), '');
    // 1. Hapus spasi di awal dan di akhir nama
    return res.trim();
  }
}
