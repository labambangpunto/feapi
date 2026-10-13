import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/pembukuan_controller.dart';
import '../controllers/transaksi_controller.dart'; // TAMBAHKAN BARIS INI
import '../models/pembukuan_model.dart';
import '../utils/currency_format.dart';
import '../models/transaksi_model.dart';

class PembukuanScreen extends ConsumerStatefulWidget {
  const PembukuanScreen({super.key});

  @override
  ConsumerState<PembukuanScreen> createState() => _PembukuanScreenState();
}

class _PembukuanScreenState extends ConsumerState<PembukuanScreen> {
  int? _selectedYear; // Diubah menjadi nullable

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
    final transaksiState = ref.watch(transaksiControllerProvider);
    final now = DateTime.now();

    final transaksiList = transaksiState.value ?? [];

    // 1. Dapatkan daftar tahun unik yang memiliki transaksi
    List<int> tahunDenganTransaksi = transaksiList
        .map((t) => t.waktu.year)
        .toSet()
        .toList();

    // Urutkan dari tahun terbaru ke terlama
    tahunDenganTransaksi.sort((a, b) => b.compareTo(a));

    // Jika belum ada transaksi sama sekali, tampilkan tahun saat ini sebagai fallback
    if (tahunDenganTransaksi.isEmpty) {
      tahunDenganTransaksi = [now.year];
    }

    // 2. Tentukan tahun yang sedang aktif
    int activeYear = _selectedYear ?? tahunDenganTransaksi.first;
    // Jika tahun yang di-select sebelumnya tiba-tiba tidak ada (misal transaksinya dihapus), reset ke tahun pertama
    if (!tahunDenganTransaksi.contains(activeYear)) {
      activeYear = tahunDenganTransaksi.first;
    }

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
                  value: activeYear, // Gunakan activeYear
                  items: tahunDenganTransaksi.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
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
                // Gunakan activeYear untuk memfilter transaksi
                final List<int> bulanDenganTransaksi = transaksiList
                    .where((t) => t.waktu.year == activeYear)
                    .map((t) => t.waktu.month)
                    .toSet()
                    .toList();

                bulanDenganTransaksi.sort();

                if (bulanDenganTransaksi.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada transaksi di tahun ini.'),
                  );
                }

                return ListView.builder(
                  itemCount: bulanDenganTransaksi.length,
                  itemBuilder: (context, index) {
                    final monthInt = bulanDenganTransaksi[index];

                    // Gunakan activeYear untuk evaluasi logika waktu
                    final isFutureOrCurrent =
                        (activeYear > now.year) ||
                        (activeYear == now.year && monthInt >= now.month);

                    PembukuanModel? currentPembukuan;
                    try {
                      currentPembukuan = pList.firstWhere(
                        (p) => p.tahun == activeYear && p.bulan == monthInt,
                      );
                    } catch (_) {}

                    final isTerkunci = currentPembukuan?.isTerkunci ?? false;

                    // 1. Hitung total transaksi (jumlah data, pemasukan, pengeluaran) untuk bulan ini
                    double totalPemasukan = 0;
                    double totalPengeluaran = 0;
                    int jumlahTransaksi = 0;

                    for (var t in transaksiList) {
                      if (t.waktu.year == activeYear &&
                          t.waktu.month == monthInt) {
                        jumlahTransaksi++;
                        final nominal =
                            (t.nominal * t.kuantitas) + (t.biayaTambahan ?? 0);
                        if (t.tipe == TipeTransaksi.pemasukan) {
                          totalPemasukan += nominal;
                        } else if (t.tipe == TipeTransaksi.pengeluaran) {
                          totalPengeluaran += nominal;
                        }
                      }
                    }

                    Widget trailingWidget;
                    if (isFutureOrCurrent) {
                      trailingWidget = const Tooltip(
                        message: 'Bulan aktif/masa depan belum bisa ditutup',
                        child: Icon(Icons.help_outline, color: Colors.grey),
                      );
                    } else {
                      trailingWidget = ElevatedButton(
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
                          activeYear,
                        ),
                        child: Text(
                          isTerkunci ? 'Buka Kunci' : 'Tutup Buku',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

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
                        title: Text('${_bulanList[monthInt - 1]} $activeYear'),
                        // 2. Tampilkan hasil perhitungan di subtitle
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTerkunci
                                  ? 'Sudah Dibukukan (Terkunci)'
                                  : 'Belum Dibukukan (Terbuka)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$jumlahTransaksi Transaksi\nMasuk: ${totalPemasukan.toIdr()} | Keluar: ${totalPengeluaran.toIdr()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: trailingWidget,
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
    int activeYear, // Tambahan parameter baru
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
          tahun: activeYear, // Gunakan activeYear alih-alih _selectedYear
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
