import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/pembukuan_controller.dart';
import '../models/pembukuan_model.dart';

class PembukuanScreen extends ConsumerStatefulWidget {
  const PembukuanScreen({super.key});

  @override
  ConsumerState<PembukuanScreen> createState() => _PembukuanScreenState();
}

class _PembukuanScreenState extends ConsumerState<PembukuanScreen> {
  int _selectedYear = DateTime.now().year;

  final List<String> _bulanList = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) {
    final pembukuanState = ref.watch(pembukuanControllerProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Pembukuan Bulanan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Tahun:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(10, (index) {
                    final year = now.year - 5 + index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: pembukuanState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (pList) {
                return ListView.builder(
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final monthInt = index + 1;

                    // Pembukuan hanya diizinkan untuk bulan yang sudah terlewati
                    final isFutureOrCurrent =
                        (_selectedYear > now.year) ||
                        (_selectedYear == now.year && monthInt >= now.month);

                    PembukuanModel? currentPembukuan;
                    try {
                      currentPembukuan = pList.firstWhere(
                        (p) => p.tahun == _selectedYear && p.bulan == monthInt,
                      );
                    } catch (_) {}

                    final isTerkunci = currentPembukuan?.isTerkunci ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: Icon(
                          isTerkunci ? Icons.lock : Icons.lock_open,
                          color: isTerkunci ? Colors.red : Colors.green,
                        ),
                        title: Text('${_bulanList[index]} $_selectedYear'),
                        subtitle: Text(
                          isTerkunci
                              ? 'Sudah Dibukukan (Terkunci)'
                              : 'Belum Dibukukan (Terbuka)',
                        ),
                        trailing: isFutureOrCurrent
                            ? const Tooltip(
                                message:
                                    'Bulan aktif/masa depan belum bisa ditutup',
                                child: Icon(
                                  Icons.help_outline,
                                  color: Colors.grey,
                                ),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isTerkunci
                                      ? Colors.orange
                                      : Colors.blue,
                                ),
                                onPressed: () => _prosesUbahStatus(
                                  context,
                                  ref,
                                  monthInt,
                                  currentPembukuan,
                                  isTerkunci,
                                ),
                                child: Text(
                                  isTerkunci ? 'Buka Kunci' : 'Tutup Buku',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _prosesUbahStatus(
    BuildContext context,
    WidgetRef ref,
    int monthInt,
    PembukuanModel? existingData,
    bool isTerkunci,
  ) async {
    final textValidasi = isTerkunci ? 'BUKA' : 'KUNCI';
    bool isChecked = false;
    final textController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(
            isTerkunci ? 'Buka Kunci Pembukuan' : 'Tutup Buku (Kunci)',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTerkunci
                    ? 'Membuka kunci memungkinkan Anda menambah/mengubah transaksi historis di bulan ini yang berisiko mengubah laporan akuntansi. Lanjutkan?'
                    : 'Menutup buku akan mengunci seluruh transaksi di bulan ini agar tidak bisa diubah atau dihapus sembarangan. Lanjutkan?',
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Saya paham konsekuensinya'),
                value: isChecked,
                onChanged: (val) =>
                    setStateDialog(() => isChecked = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: 'Ketik "$textValidasi" untuk konfirmasi',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) => setStateDialog(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: (isChecked && textController.text == textValidasi)
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text('Konfirmasi'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (existingData != null) {
        final updated = PembukuanModel(
          id: existingData.id,
          tahun: existingData.tahun,
          bulan: existingData.bulan,
          isTerkunci: !isTerkunci,
        );
        ref.read(pembukuanControllerProvider.notifier).updatePembukuan(updated);
      } else {
        final newData = PembukuanModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tahun: _selectedYear,
          bulan: monthInt,
          isTerkunci: true,
        );
        ref.read(pembukuanControllerProvider.notifier).tambahPembukuan(newData);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTerkunci
                  ? 'Kunci bulan berhasil dibuka.'
                  : 'Bulan berhasil dibukukan dan dikunci.',
            ),
          ),
        );
      }
    }
  }
}
