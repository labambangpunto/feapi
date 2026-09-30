import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/label_controller.dart';
import '../models/label_model.dart';

class KelolaLabelScreen extends ConsumerWidget {
  const KelolaLabelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelState = ref.watch(labelControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Label')),
      body: labelState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (labelList) {
          if (labelList.isEmpty) {
            return const Center(child: Text('Belum ada label'));
          }
          return ListView.builder(
            itemCount: labelList.length,
            itemBuilder: (context, index) {
              final label = labelList[index];
              return ListTile(
                title: Text(label.nama),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () =>
                          _tampilFormFormLabel(context, ref, dataEdit: label),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref
                            .read(labelControllerProvider.notifier)
                            .hapusLabel(label.id);
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
        onPressed: () => _tampilFormFormLabel(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _tampilFormFormLabel(
    BuildContext context,
    WidgetRef ref, {
    LabelModel? dataEdit,
  }) {
    final namaController = TextEditingController(text: dataEdit?.nama ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dataEdit == null ? 'Tambah Label' : 'Edit Label'),
        content: TextField(
          controller: namaController,
          decoration: const InputDecoration(labelText: 'Nama label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final namaLabel = namaController.text.trim();
              if (namaLabel.isEmpty) return;

              final currentLabel =
                  ref.read(labelControllerProvider).value ?? [];

              // Cek duplikasi dengan mengabaikan ID jika sedang mode edit
              final isDuplicate = currentLabel.any(
                (l) =>
                    l.id != dataEdit?.id &&
                    l.nama.toLowerCase() == namaLabel.toLowerCase(),
              );

              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama label sudah digunakan')),
                );
                return;
              }

              final label = LabelModel(
                id:
                    dataEdit?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                nama: namaLabel,
              );

              if (dataEdit != null) {
                ref.read(labelControllerProvider.notifier).updateLabel(label);
              } else {
                ref.read(labelControllerProvider.notifier).tambahLabel(label);
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
