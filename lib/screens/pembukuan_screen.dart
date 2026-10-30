import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/pembukuan_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../controllers/utang_piutang_controller.dart';
import '../models/pembukuan_model.dart';
import '../models/utang_piutang_model.dart';
import '../utils/currency_format.dart';
import '../models/transaksi_model.dart';

class PembukuanScreen extends ConsumerStatefulWidget {
  const PembukuanScreen({super.key});

  @override
  ConsumerState<PembukuanScreen> createState() => _PembukuanScreenState();
}

class _PembukuanScreenState extends ConsumerState<PembukuanScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedYear;
  late TabController _tabController;

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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pembukuanState = ref.watch(pembukuanControllerProvider);
    final transaksiState = ref.watch(transaksiControllerProvider);
    final utangState = ref.watch(utangPiutangControllerProvider);
    final now = DateTime.now();

    final transaksiList = transaksiState.value ?? [];
    final utangList = utangState.value ?? [];

    // Gabungkan tahun dari transaksi dan utang-piutang
    Set<int> setTahun = {
      ...transaksiList.map((t) => t.waktu.year),
      ...utangList.map((u) => u.waktu.year),
    };
    List<int> tahunList = setTahun.toList()..sort((a, b) => b.compareTo(a));

    if (tahunList.isEmpty) {
      tahunList = [now.year];
    }

    int activeYear = _selectedYear ?? tahunList.first;
    if (!tahunList.contains(activeYear)) {
      activeYear = tahunList.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembukuan Bulanan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Transaksi'),
            Tab(icon: Icon(Icons.handshake), text: 'Utang & Piutang'),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: MediaQuery.of(context).size.width < 320
                ? 320
                : MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Tahun:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<int>(
                        value: activeYear,
                        items: tahunList.map((year) {
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
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // DIVISI 1: PEMBUKUAN TRANSAKSI
                      _buildDaftarPembukuan(
                        context: context,
                        ref: ref,
                        tipeDivisi: 'transaksi',
                        pList: pembukuanState.value ?? [],
                        activeYear: activeYear,
                        now: now,
                        dataList: transaksiList,
                      ),
                      // DIVISI 2: PEMBUKUAN UTANG-PIUTANG
                      _buildDaftarPembukuan(
                        context: context,
                        ref: ref,
                        tipeDivisi: 'utang_piutang',
                        pList: pembukuanState.value ?? [],
                        activeYear: activeYear,
                        now: now,
                        dataList: utangList,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDaftarPembukuan({
    required BuildContext context,
    required WidgetRef ref,
    required String tipeDivisi,
    required List<PembukuanModel> pList,
    required int activeYear,
    required DateTime now,
    required List<dynamic> dataList,
  }) {
    List<int> bulanDenganData = [];

    if (tipeDivisi == 'transaksi') {
      bulanDenganData =
          (dataList as List<TransaksiModel>)
              .where((t) => t.waktu.year == activeYear)
              .map((t) => t.waktu.month)
              .toSet()
              .toList()
            ..sort();
    } else {
      bulanDenganData =
          (dataList as List<UtangPiutangModel>)
              .where((u) => u.waktu.year == activeYear)
              .map((u) => u.waktu.month)
              .toSet()
              .toList()
            ..sort();
    }

    if (bulanDenganData.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data ${tipeDivisi == "transaksi" ? "transaksi" : "utang/piutang"} di tahun ini.',
        ),
      );
    }

    return ListView.builder(
      itemCount: bulanDenganData.length,
      itemBuilder: (context, index) {
        final monthInt = bulanDenganData[index];
        final isFutureOrCurrent =
            (activeYear > now.year) ||
            (activeYear == now.year && monthInt >= now.month);

        PembukuanModel? currentPembukuan;
        try {
          currentPembukuan = pList.firstWhere(
            (p) =>
                p.tahun == activeYear &&
                p.bulan == monthInt &&
                p.tipe == tipeDivisi,
          );
        } catch (_) {}

        final isTerkunci = currentPembukuan?.isTerkunci ?? false;

        String subtitleInfo = '';
        if (tipeDivisi == 'transaksi') {
          double totalPemasukan = 0;
          double totalPengeluaran = 0;
          int jumlah = 0;

          for (var t in (dataList as List<TransaksiModel>)) {
            if (t.waktu.year == activeYear && t.waktu.month == monthInt) {
              jumlah++;
              final nominal =
                  (t.nominal * t.kuantitas) + (t.biayaTambahan ?? 0);
              if (t.tipe == TipeTransaksi.pemasukan) {
                totalPemasukan += nominal;
              } else if (t.tipe == TipeTransaksi.pengeluaran) {
                totalPengeluaran += nominal;
              }
            }
          }
          subtitleInfo =
              '$jumlah Transaksi\nMasuk: ${totalPemasukan.toIdr()} | Keluar: ${totalPengeluaran.toIdr()}';
        } else {
          double totalUtang = 0;
          double totalPiutang = 0;
          int jumlah = 0;

          for (var u in (dataList as List<UtangPiutangModel>)) {
            if (u.waktu.year == activeYear && u.waktu.month == monthInt) {
              jumlah++;
              if (u.tipe == TipeUtangPiutang.utang) {
                totalUtang += u.nominal;
              } else {
                totalPiutang += u.nominal;
              }
            }
          }
          subtitleInfo =
              '$jumlah Catatan Utang/Piutang\nUtang: ${totalUtang.toIdr()} | Piutang: ${totalPiutang.toIdr()}';
        }

        Widget trailingWidget = isFutureOrCurrent
            ? const Tooltip(
                message: 'Bulan aktif/masa depan belum bisa ditutup',
                child: Icon(Icons.help_outline, color: Colors.grey),
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTerkunci ? Colors.orange : Colors.blue,
                ),
                onPressed: () {
                  // Validasi cegah tutup buku utang/piutang jika ada yang belum lunas
                  if (!isTerkunci && tipeDivisi == 'utang_piutang') {
                    final hasBelumLunas = (dataList as List<UtangPiutangModel>)
                        .any(
                          (u) =>
                              u.waktu.year == activeYear &&
                              u.waktu.month == monthInt &&
                              !u.isLunas,
                        );

                    if (hasBelumLunas) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Gagal menutup buku: Masih ada utang/piutang yang belum lunas di bulan ini.',
                          ),
                        ),
                      );
                      return; // Hentikan proses jika belum lunas semua
                    }
                  }

                  _prosesUbahStatus(
                    context,
                    ref,
                    monthInt,
                    currentPembukuan,
                    isTerkunci,
                    activeYear,
                    tipeDivisi,
                  );
                },
                child: Text(
                  isTerkunci ? 'Buka Kunci' : 'Tutup Buku',
                  style: const TextStyle(color: Colors.white),
                ),
              );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Icon(
              isTerkunci ? Icons.lock : Icons.lock_open,
              color: isTerkunci ? Colors.red : Colors.green,
            ),
            title: Text('${_bulanList[monthInt - 1]} $activeYear'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTerkunci
                      ? 'Sudah Dibukukan (Terkunci)'
                      : 'Belum Dibukukan (Terbuka)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(subtitleInfo, style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: trailingWidget,
          ),
        );
      },
    );
  }

  void _prosesUbahStatus(
    BuildContext context,
    WidgetRef ref,
    int monthInt,
    PembukuanModel? existingData,
    bool isTerkunci,
    int activeYear,
    String tipeDivisi,
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
                    ? 'Membuka kunci memungkinkan Anda menambah/mengubah data di bulan ini. Lanjutkan?'
                    : 'Menutup buku akan mengunci data di bulan ini agar tidak bisa diubah atau dihapus. Lanjutkan?',
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
          tipe: tipeDivisi,
        );
        ref.read(pembukuanControllerProvider.notifier).updatePembukuan(updated);
      } else {
        final newData = PembukuanModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tahun: activeYear,
          bulan: monthInt,
          isTerkunci: true,
          tipe: tipeDivisi,
        );
        ref.read(pembukuanControllerProvider.notifier).tambahPembukuan(newData);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTerkunci
                  ? 'Kunci pembukuan berhasil dibuka.'
                  : 'Bulan berhasil dibukukan dan dikunci.',
            ),
          ),
        );
      }
    }
  }
}
