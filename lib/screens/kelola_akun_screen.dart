import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../controllers/akun_controller.dart';
import '../models/akun_model.dart';
import '../utils/currency_format.dart';
import '../utils/currency_formatter.dart';

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
                subtitle: Text('Saldo awal: ${akun.saldoAwal.toIdr()}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _tampilFormEditAkun(context, ref, akun),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref
                            .read(akunControllerProvider.notifier)
                            .hapusAkun(akun.id);
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

  void _tampilFormTambahAkun(BuildContext context, WidgetRef ref) {
    final namaController = TextEditingController();
    final saldoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Akun Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama akun'),
            ),
            TextField(
              controller: saldoController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyFormatter(), // Sesuaikan dengan nama class yang ada di currency_formatter.dart Anda
              ],
              decoration: const InputDecoration(
                labelText: 'Saldo awal (Permanen)',
                prefixText: 'Rp ',
                helperText: 'Saldo awal tidak dapat \ndiubah setelah disimpan.',
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
              final namaBaru = namaController.text.trim();
              if (namaBaru.isEmpty) return;

              // Ambil daftar akun saat ini
              final currentAkun = ref.read(akunControllerProvider).value ?? [];

              // Cek duplikasi (case-insensitive)
              final isDuplicate = currentAkun.any(
                (a) => a.nama.toLowerCase() == namaBaru.toLowerCase(),
              );

              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama akun sudah digunakan')),
                );
                return; // Hentikan proses simpan
              }

              final akun = AkunModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                nama: namaBaru,
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(labelText: 'Nama akun'),
            ),
            const SizedBox(height: 16),
            Text(
              'Saldo awal: ${akunLama.saldoAwal.toIdr()}\n(Saldo awal tidak dapat diedit)',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
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
              final namaEdit = namaController.text.trim();
              if (namaEdit.isEmpty) return;

              final currentAkun = ref.read(akunControllerProvider).value ?? [];

              // Cek duplikasi dengan mengabaikan ID akun yang sedang diedit
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

              final akunUpdate = AkunModel(
                id: akunLama.id,
                nama: namaEdit,
                saldoAwal: akunLama.saldoAwal,
              );
              ref.read(akunControllerProvider.notifier).updateAkun(akunUpdate);
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
