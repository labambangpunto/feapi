import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/label_controller.dart';
import '../controllers/transaksi_controller.dart';
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: labelList.length,
            itemBuilder: (context, index) {
              final label = labelList[index];
              final isDibekukan = label.isDibekukan;
              final isDefault =
                  label.id == 'label_utang' || label.id == 'label_piutang';

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      label.nama,
                      style: TextStyle(
                        decoration: isDibekukan
                            ? TextDecoration.lineThrough
                            : null,
                        color: isDibekukan ? Colors.grey : Colors.black,
                        fontWeight: isDefault
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: isDefault
                        ? const Text(
                            'Label Default Sistem',
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          )
                        : (isDibekukan
                              ? const Text(
                                  'Dibekukan',
                                  style: TextStyle(color: Colors.red),
                                )
                              : null),
                    trailing: isDefault
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isDibekukan)
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _tampilFormFormLabel(
                                    context,
                                    ref,
                                    dataEdit: label,
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  isDibekukan ? Icons.restore : Icons.delete,
                                  color: isDibekukan
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                onPressed: () {
                                  if (isDibekukan) {
                                    _pulihkanLabel(context, ref, label);
                                  } else {
                                    _cekDanHapusAtauBekukan(
                                      context,
                                      ref,
                                      label,
                                    );
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
        onPressed: () => _tampilFormFormLabel(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _cekDanHapusAtauBekukan(
    BuildContext context,
    WidgetRef ref,
    LabelModel label,
  ) {
    final transaksiList = ref.read(transaksiControllerProvider).value ?? [];
    final isDigunakanDiTransaksi = transaksiList.any(
      (t) => t.labelId == label.id,
    );

    if (isDigunakanDiTransaksi) {
      _tampilDialogBekukanLabel(context, ref, label);
    } else {
      _tampilDialogHapusLabel(context, ref, label);
    }
  }

  void _tampilDialogBekukanLabel(
    BuildContext context,
    WidgetRef ref,
    LabelModel label,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Label Sedang Digunakan'),
        content: Text(
          'Label "${label.nama}" tidak bisa dihapus karena terikat pada transaksi.\n\nApakah Anda ingin membekukannya? (Label tidak akan muncul di form input baru)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final labelDibekukan = label.copyWith(isDibekukan: true);
              ref
                  .read(labelControllerProvider.notifier)
                  .updateLabel(labelDibekukan);
              Navigator.pop(dialogContext);
            },
            child: const Text('Bekukan'),
          ),
        ],
      ),
    );
  }

  void _pulihkanLabel(BuildContext context, WidgetRef ref, LabelModel label) {
    final labelDipulihkan = label.copyWith(isDibekukan: false);
    ref.read(labelControllerProvider.notifier).updateLabel(labelDipulihkan);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Label berhasil dipulihkan')));
  }

  void _tampilFormFormLabel(
    BuildContext context,
    WidgetRef ref, {
    LabelModel? dataEdit,
  }) {
    final namaController = TextEditingController(text: dataEdit?.nama ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dataEdit == null ? 'Tambah Label' : 'Edit Label'),
        content: TextField(
          controller: namaController,
          decoration: const InputDecoration(labelText: 'Nama label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final namaLabel = _autoFormatNama(namaController.text);
              if (namaLabel.isEmpty) return;

              final currentLabel =
                  ref.read(labelControllerProvider).value ?? [];
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
                isDibekukan: dataEdit?.isDibekukan ?? false,
              );

              if (dataEdit != null) {
                ref.read(labelControllerProvider.notifier).updateLabel(label);
              } else {
                ref.read(labelControllerProvider.notifier).tambahLabel(label);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _tampilDialogHapusLabel(
    BuildContext context,
    WidgetRef ref,
    LabelModel label,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Label'),
        content: Text(
          'Apakah Anda yakin ingin menghapus label "${label.nama}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(labelControllerProvider.notifier).hapusLabel(label.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus'),
          ),
        ],
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
