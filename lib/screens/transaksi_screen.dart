import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/transaksi_controller.dart';
import '../controllers/akun_controller.dart';
import '../controllers/label_controller.dart';
import '../models/transaksi_model.dart';
import '../models/akun_model.dart';
import '../models/label_model.dart';
import '../utils/currency_format.dart';
import '../utils/currency_formatter.dart';
import '../controllers/pembukuan_controller.dart';
import 'form_transaksi.dart';

class TransaksiScreen extends ConsumerStatefulWidget {
  const TransaksiScreen({super.key});

  @override
  ConsumerState<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends ConsumerState<TransaksiScreen> {
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();

  bool _showFullMonth = false;

  bool _isFilterActive = false;
  String _filterCatatan = '';
  String? _filterAkunId;
  String? _filterLabelId;
  double? _filterMinNominal;
  double? _filterMaxNominal;
  TipeTransaksi? _filterTipe;

  @override
  Widget build(BuildContext context) {
    final transaksiState = ref.watch(transaksiControllerProvider);
    final akunList = ref.watch(akunControllerProvider).value ?? [];
    final labelList = ref.watch(labelControllerProvider).value ?? [];
    final pembukuanState = ref.watch(pembukuanControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Transaksi'),
        actions: [
          if (_isFilterActive)
            Tooltip(
              message: 'Hapus Filter',
              child: IconButton(
                icon: const Icon(Icons.filter_alt_off),
                onPressed: () {
                  setState(() {
                    _isFilterActive = false;
                    _filterCatatan = '';
                    _filterAkunId = null;
                    _filterLabelId = null;
                    _filterMinNominal = null;
                    _filterMaxNominal = null;
                    _filterTipe = null;
                  });
                },
              ),
            )
          else
            Tooltip(
              message: 'Cari / Filter',
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _tampilFormFilter(akunList, labelList),
              ),
            ),
          Tooltip(
            message: 'Jump to Date',
            child: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _showFullMonth = false;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: transaksiState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (transaksiList) {
          bool isBulanTerkunci(DateTime dt) {
            final pList = pembukuanState.value ?? [];
            return pList.any(
              (p) => p.tahun == dt.year && p.bulan == dt.month && p.isTerkunci,
            );
          }

          String getAkunName(String? id) {
            if (id == null) return '-';
            try {
              return akunList.firstWhere((a) => a.id == id).nama;
            } catch (_) {
              return 'Akun terhapus';
            }
          }

          List<String> getLabelNames(String? ids) {
            if (ids == null || ids.isEmpty) return [];
            return ids.split(',').map((id) {
              try {
                return labelList.firstWhere((l) => l.id == id).nama;
              } catch (_) {
                return 'Label terhapus';
              }
            }).toList();
          }

          var filteredList = transaksiList;

          if (!_isFilterActive) {
            if (!_showFullMonth) {
              filteredList = filteredList
                  .where(
                    (t) =>
                        t.waktu.year == _selectedDate.year &&
                        t.waktu.month == _selectedDate.month &&
                        t.waktu.day == _selectedDate.day,
                  )
                  .toList();
            } else {
              filteredList = filteredList
                  .where(
                    (t) =>
                        t.waktu.year == _selectedDate.year &&
                        t.waktu.month == _selectedDate.month,
                  )
                  .toList();
            }
          } else {
            filteredList = filteredList
                .where(
                  (t) =>
                      t.waktu.year == _selectedDate.year &&
                      t.waktu.month == _selectedDate.month,
                )
                .toList();

            if (_filterTipe != null) {
              filteredList = filteredList
                  .where((t) => t.tipe == _filterTipe)
                  .toList();
            }
            if (_filterCatatan.isNotEmpty) {
              final query = _filterCatatan.toLowerCase();
              filteredList = filteredList
                  .where((t) => t.catatan.toLowerCase().contains(query))
                  .toList();
            }
            if (_filterAkunId != null) {
              filteredList = filteredList
                  .where(
                    (t) =>
                        t.akunSumberId == _filterAkunId ||
                        t.akunTujuanId == _filterAkunId,
                  )
                  .toList();
            }
            if (_filterLabelId != null) {
              filteredList = filteredList.where((t) {
                if (t.labelId == null || t.labelId!.isEmpty) return false;
                final labels = t.labelId!.split(',');
                return labels.contains(_filterLabelId);
              }).toList();
            }
            if (_filterMinNominal != null) {
              filteredList = filteredList
                  .where((t) => t.nominal >= _filterMinNominal!)
                  .toList();
            }
            if (_filterMaxNominal != null) {
              filteredList = filteredList
                  .where((t) => t.nominal <= _filterMaxNominal!)
                  .toList();
            }
          }

          filteredList.sort((a, b) => b.waktu.compareTo(a.waktu));

          const bulanMap = [
            '',
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'Mei',
            'Jun',
            'Jul',
            'Agt',
            'Sep',
            'Okt',
            'Nov',
            'Des',
          ];
          final displayDate =
              '${_selectedDate.day.toString().padLeft(2, '0')} ${bulanMap[_selectedDate.month]} ${_selectedDate.year}';
          final displayMonth =
              '${bulanMap[_selectedDate.month]} ${_selectedDate.year}';

          final String topLabelInfo = _isFilterActive
              ? 'Pencarian di bulan: $displayMonth'
              : _showFullMonth
              ? 'Riwayat bulan: $displayMonth'
              : 'Transaksi tanggal: $displayDate';

          String formatHeadingTanggal(DateTime dt) {
            const hariMap = [
              '',
              'Senin',
              'Selasa',
              'Rabu',
              'Kamis',
              'Jumat',
              'Sabtu',
              'Minggu',
            ];
            return '${hariMap[dt.weekday]}, ${dt.day.toString().padLeft(2, '0')} ${bulanMap[dt.month]} ${dt.year}';
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                color: _isFilterActive
                    ? Colors.orange.withValues(alpha: 0.15)
                    : Colors.blue.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isFilterActive ? Icons.search : Icons.today,
                      size: 16,
                      color: _isFilterActive
                          ? Colors.orange[800]
                          : Colors.blue[800],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      topLabelInfo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isFilterActive
                            ? Colors.orange[800]
                            : Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    filteredList.isEmpty && (_isFilterActive || _showFullMonth)
                    ? const Center(
                        child: Text('Tidak ada transaksi yang cocok'),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Deteksi lebar layar untuk mengatur jumlah kolom grid
                          final isDesktop = constraints.maxWidth > 600;
                          final crossAxisCount = isDesktop ? 4 : 1;

                          // Kelompokkan data per tanggal agar header tanggal dapat memisahkan setiap grup (full-width)
                          final Map<String, List<TransaksiModel>>
                          groupedTransactions = {};
                          for (var t in filteredList) {
                            final dateKey =
                                '${t.waktu.year}-${t.waktu.month}-${t.waktu.day}';
                            groupedTransactions
                                .putIfAbsent(dateKey, () => [])
                                .add(t);
                          }

                          return CustomScrollView(
                            controller: _scrollController,
                            slivers: [
                              for (final entry
                                  in groupedTransactions.entries) ...[
                                // Header Tanggal (Full-Width)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      4,
                                    ),
                                    child: Text(
                                      formatHeadingTanggal(
                                        entry.value.first.waktu,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.blueGrey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                                // Grid Transaksi per Tanggal
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          mainAxisExtent: 110, // Ketinggian tetap untuk card transaksi (mencegah overflow)
                                          crossAxisSpacing: 4,
                                          mainAxisSpacing: 4,
                                        ),
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final t = entry.value[index];

                                      final double totalNominal =
                                          (t.nominal * t.kuantitas) +
                                          (t.biayaTambahan ?? 0);
                                      String namaSumber = getAkunName(
                                        t.akunSumberId,
                                      );
                                      String namaTujuan = getAkunName(
                                        t.akunTujuanId,
                                      );
                                      List<String> namaLabels = getLabelNames(
                                        t.labelId,
                                      );

                                      IconData iconTipe;
                                      Color colorTipe;
                                      String textAkun;

                                      if (t.tipe == TipeTransaksi.pemasukan) {
                                        iconTipe = Icons.arrow_downward;
                                        colorTipe = Colors.green;
                                        textAkun = 'Ke $namaTujuan';
                                      } else if (t.tipe ==
                                          TipeTransaksi.pengeluaran) {
                                        iconTipe = Icons.arrow_upward;
                                        colorTipe = Colors.red;
                                        textAkun = 'Dari $namaSumber';
                                      } else {
                                        iconTipe = Icons.swap_horiz;
                                        colorTipe = Colors.blue;
                                        textAkun = '$namaSumber ➔ $namaTujuan';
                                      }

                                      final bool isTerkunci = isBulanTerkunci(
                                        t.waktu,
                                      );

                                      return Card(
                                        elevation: 2,
                                        clipBehavior: Clip.antiAlias,
                                        color: isTerkunci
                                            ? Colors.grey.shade100
                                            : null,
                                        child: InkWell(
                                          onTap: () => _tampilSummaryTransaksi(
                                            context,
                                            t,
                                            namaSumber,
                                            namaTujuan,
                                            namaLabels,
                                            isTerkunci,
                                          ),
                                          child: Center(
                                            // Ubah Padding menjadi Center
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: colorTipe
                                                    .withValues(alpha: 0.15),
                                                child: Icon(
                                                  iconTipe,
                                                  color: colorTipe,
                                                ),
                                              ),
                                              title: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      totalNominal.toIdr(),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: isTerkunci
                                                            ? Colors.grey
                                                            : colorTipe,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isTerkunci) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.lock,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              subtitle: Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min, // Tambahkan baris ini
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      t.catatan,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      textAkun,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }, childCount: entry.value.length),
                                  ),
                                ),
                              ],
                              // Footer / Pemuat Transaksi Bulan Ini
                              if (!_isFilterActive && !_showFullMonth)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (filteredList.isEmpty) ...[
                                          const Icon(
                                            Icons.receipt_long,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Tidak ada transaksi di tanggal ini.',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        OutlinedButton(
                                          onPressed: () => setState(
                                            () => _showFullMonth = true,
                                          ),
                                          child: const Text(
                                            'Transaksi Bulan Ini',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.arrow_upward,
                        color: Colors.red,
                      ),
                      title: const Text('Pengeluaran'),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FormTransaksiScreen(
                              tipeTransaksi: TipeTransaksi.pengeluaran,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.arrow_downward,
                        color: Colors.green,
                      ),
                      title: const Text('Pemasukan'),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FormTransaksiScreen(
                              tipeTransaksi: TipeTransaksi.pemasukan,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                      title: const Text('Transfer Antarakun'),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FormTransaksiScreen(
                              tipeTransaksi: TipeTransaksi.transfer,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _tampilSummaryTransaksi(
    BuildContext context,
    TransaksiModel t,
    String namaSumber,
    String namaTujuan,
    List<String> namaLabels,
    bool isTerkunci, // Parameter baru
  ) {
    final double totalNominal =
        (t.nominal * t.kuantitas) + (t.biayaTambahan ?? 0);
    const bulanMap = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final tglStr =
        '${t.waktu.day.toString().padLeft(2, '0')} ${bulanMap[t.waktu.month]} ${t.waktu.year}';

    final isPengeluaran = t.tipe == TipeTransaksi.pengeluaran;
    final isPemasukan = t.tipe == TipeTransaksi.pemasukan;
    final isTransfer = t.tipe == TipeTransaksi.transfer;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detail Transaksi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Logika Tampilan Nominal Baru
              if ((isPengeluaran || isTransfer) &&
                  t.biayaTambahan != null &&
                  t.biayaTambahan! > 0) ...[
                Text(
                  'Nominal: ${(t.nominal * t.kuantitas).toIdr()}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'Biaya Tambahan: ${t.biayaTambahan!.toIdr()}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const Divider(),
                Text(
                  'Total: ${totalNominal.toIdr()}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isPengeluaran ? Colors.red : Colors.blue,
                  ),
                ),
              ] else ...[
                Text(
                  totalNominal.toIdr(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isPemasukan
                        ? Colors.green
                        : (isPengeluaran ? Colors.red : Colors.blue),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Text(
                t.catatan,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              // 2. Tampilan Info Tambahan (Biaya Tambahan Dihapus dari Sini)
              if (isPengeluaran) ...[
                Text('Kuantitas: ${t.kuantitas}'),
                const SizedBox(height: 4),
                Text('Sumber dana: $namaSumber'),
              ] else if (isPemasukan) ...[
                Text('Tujuan dana: $namaTujuan'),
              ] else if (isTransfer) ...[
                const SizedBox(height: 4),
                Text('Dari: $namaSumber'),
                Text('Ke: $namaTujuan'),
              ],
              const SizedBox(height: 12),
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Text(tglStr, style: const TextStyle(fontSize: 16)),
                ],
              ),
              if (namaLabels.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: namaLabels
                      .map(
                        (nl) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.grey, // warna border
                              width: 1, // ketebalan border
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.label_outline,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(nl, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Sembunyikan tombol Edit & Hapus jika bulan terkunci
          if (!isTerkunci)
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog detail
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Konfirmasi Hapus'),
                    content: const Text(
                      'Apakah Anda yakin ingin menghapus transaksi ini?',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      FilledButton(
                        onPressed: () {
                          ref
                              .read(transaksiControllerProvider.notifier)
                              .hapusTransaksi(t.id);
                          Navigator.pop(context);
                        },
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 191, 71, 71),
              ),
              child: const Text('Hapus'),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          if (!isTerkunci) const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FormTransaksiScreen(tipeTransaksi: t.tipe, dataEdit: t),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _tampilFormFilter(List<AkunModel> akunList, List<LabelModel> labelList) {
    String tempCatatan = _filterCatatan;
    String? tempAkunId = _filterAkunId;
    String? tempLabelId = _filterLabelId;
    TipeTransaksi? tempTipe = _filterTipe;

    final catatanCtrl = TextEditingController(text: tempCatatan);
    final minCtrl = TextEditingController(
      text: _filterMinNominal != null ? _filterMinNominal!.toRibuan() : '',
    );
    final maxCtrl = TextEditingController(
      text: _filterMaxNominal != null ? _filterMaxNominal!.toRibuan() : '',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextState, setStateDialog) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<TipeTransaksi?>(
                      initialValue: tempTipe,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Transaksi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Semua')),
                        DropdownMenuItem(
                          value: TipeTransaksi.pemasukan,
                          child: Text('Pemasukan'),
                        ),
                        DropdownMenuItem(
                          value: TipeTransaksi.pengeluaran,
                          child: Text('Pengeluaran'),
                        ),
                        DropdownMenuItem(
                          value: TipeTransaksi.transfer,
                          child: Text('Transfer Antarakun'),
                        ),
                      ],
                      onChanged: (val) => setStateDialog(() => tempTipe = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: catatanCtrl,
                      maxLength: 64,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => tempCatatan = val,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tempAkunId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Akun',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Semua'),
                        ),
                        ...akunList.map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.nama),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setStateDialog(() => tempAkunId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tempLabelId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Label',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Semua'),
                        ),
                        ...labelList.map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.nama),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setStateDialog(() => tempLabelId = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyFormatter()],
                            maxLength: 11,
                            decoration: const InputDecoration(
                              labelText: 'Min (Rp)',
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyFormatter()],
                            maxLength: 11,
                            decoration: const InputDecoration(
                              labelText: 'Max (Rp)',
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setState(() {
                      _isFilterActive = false;
                      _filterCatatan = '';
                      _filterAkunId = null;
                      _filterLabelId = null;
                      _filterMinNominal = null;
                      _filterMaxNominal = null;
                      _filterTipe = null;
                    });
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setState(() {
                      _filterCatatan = tempCatatan.trim();
                      _filterAkunId = tempAkunId;
                      _filterLabelId = tempLabelId;
                      _filterTipe = tempTipe;

                      _filterMinNominal = minCtrl.text.isNotEmpty
                          ? double.parse(minCtrl.text.replaceAll('.', ''))
                          : null;
                      _filterMaxNominal = maxCtrl.text.isNotEmpty
                          ? double.parse(maxCtrl.text.replaceAll('.', ''))
                          : null;

                      _isFilterActive =
                          _filterCatatan.isNotEmpty ||
                          _filterAkunId != null ||
                          _filterLabelId != null ||
                          _filterMinNominal != null ||
                          _filterMaxNominal != null ||
                          _filterTipe != null;
                    });
                  },
                  child: const Text('Cari'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
