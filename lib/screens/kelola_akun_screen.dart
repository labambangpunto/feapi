import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/akun_controller.dart';
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

              return ListTile(
                title: Text(akun.nama),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _tampilFormEditAkun(context, ref, akun),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _tampilDialogHapusAkun(context, ref, akun),
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

  void _tampilFormTambahAkun(BuildContext context, WidgetRef ref) {
    final namaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah Akun Baru'),
          content: TextField(
            controller: namaController,
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
                      final namaBaru = namaController.text.trim();
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
          decoration: const InputDecoration(labelText: 'Nama akun'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final namaEdit = namaController.text.trim();
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

              final akunUpdate = AkunModel(id: akunLama.id, nama: namaEdit);
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
}
