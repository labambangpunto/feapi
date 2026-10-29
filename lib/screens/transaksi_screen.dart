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

final showFullMonthProvider = StateProvider<bool>((ref) => false);
//
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final isModeRentangProvider = StateProvider<bool>((ref) => false);
final rentangAwalProvider = StateProvider<DateTime?>((ref) => null);
final rentangAkhirProvider = StateProvider<DateTime?>((ref) => null);
//
final isFilterActiveProvider = StateProvider<bool>((ref) => false);
final filterCatatanProvider = StateProvider<String>((ref) => '');
final filterAkunIdProvider = StateProvider<String?>((ref) => null);
final filterLabelIdProvider = StateProvider<String?>((ref) => null);
final filterMinNominalProvider = StateProvider<double?>((ref) => null);
final filterMaxNominalProvider = StateProvider<double?>((ref) => null);
final filterTipeProvider = StateProvider<TipeTransaksi?>((ref) => null);

//
class TransaksiScreen extends ConsumerStatefulWidget {
  const TransaksiScreen({super.key});

  @override
  ConsumerState<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends ConsumerState<TransaksiScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final showFullMonth = ref.watch(showFullMonthProvider);
    //
    final selectedDate = ref.watch(selectedDateProvider);
    final isModeRentang = ref.watch(isModeRentangProvider);
    final rentangAwal = ref.watch(rentangAwalProvider);
    final rentangAkhir = ref.watch(rentangAkhirProvider);

    //
    final isFilterActive = ref.watch(isFilterActiveProvider);
    final filterCatatan = ref.watch(filterCatatanProvider);
    final filterAkunId = ref.watch(filterAkunIdProvider);
    final filterLabelId = ref.watch(filterLabelIdProvider);
    final filterMinNominal = ref.watch(filterMinNominalProvider);
    final filterMaxNominal = ref.watch(filterMaxNominalProvider);
    final filterTipe = ref.watch(filterTipeProvider);
    //
    final transaksiState = ref.watch(transaksiControllerProvider);
    final akunList = ref.watch(akunControllerProvider).value ?? [];
    final labelList = ref.watch(labelControllerProvider).value ?? [];
    final pembukuanState = ref.watch(pembukuanControllerProvider);

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
        '${selectedDate.day.toString().padLeft(2, '0')} ${bulanMap[selectedDate.month]} ${selectedDate.year}';
    final displayMonth = '${bulanMap[selectedDate.month]} ${selectedDate.year}';

    String topLabelInfo = '';
    if (isModeRentang && rentangAwal != null && rentangAkhir != null) {
      final strAwal =
          '${rentangAwal.day.toString().padLeft(2, '0')} ${bulanMap[rentangAwal.month]}';
      final strAkhir =
          '${rentangAkhir.day.toString().padLeft(2, '0')} ${bulanMap[rentangAkhir.month]} ${rentangAkhir.year}';
      topLabelInfo = isFilterActive
          ? 'Filter rentang $strAwal - $strAkhir'
          : 'Rentang $strAwal - $strAkhir';
    } else if (showFullMonth || isFilterActive) {
      topLabelInfo = isFilterActive
          ? 'Filter bulan $displayMonth'
          : 'Transaksi bulan $displayMonth';
    } else {
      topLabelInfo = 'Transaksi $displayDate';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          topLabelInfo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isFilterActive)
            Tooltip(
              message: 'Hapus Filter',
              child: IconButton(
                icon: const Icon(Icons.filter_alt_off),
                onPressed: () {
                  ref.read(isFilterActiveProvider.notifier).state = false;
                  ref.read(filterCatatanProvider.notifier).state = '';
                  ref.read(filterAkunIdProvider.notifier).state = null;
                  ref.read(filterLabelIdProvider.notifier).state = null;
                  ref.read(filterMinNominalProvider.notifier).state = null;
                  ref.read(filterMaxNominalProvider.notifier).state = null;
                  ref.read(filterTipeProvider.notifier).state = null;
                },
              ),
            )
          else
            Tooltip(
              message: 'Filter', // Mengubah nama Tooltip
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () =>
                    _tampilFormFilter(akunList, labelList, ref), // Melempar ref
              ),
            ),
          Tooltip(
            message: 'Jump to Date',
            child: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () {
                if (transaksiState.hasValue) {
                  _tampilFormJumpToDate(transaksiState.value!, ref);
                }
              },
            ),
          ),
          // TOMBOL CLEAR JUMP TO DATE
          if (isModeRentang ||
              selectedDate.year != DateTime.now().year ||
              selectedDate.month != DateTime.now().month ||
              selectedDate.day != DateTime.now().day)
            Tooltip(
              message: 'Clear',
              child: IconButton(
                icon: const Icon(Icons.event_busy),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state =
                      DateTime.now();
                  ref.read(isModeRentangProvider.notifier).state = false;
                  ref.read(rentangAwalProvider.notifier).state = null;
                  ref.read(rentangAkhirProvider.notifier).state = null;
                  ref.read(showFullMonthProvider.notifier).state = false;
                },
              ),
            ),
          if (!isFilterActive &&
              !isModeRentang &&
              selectedDate.year == DateTime.now().year &&
              selectedDate.month == DateTime.now().month &&
              selectedDate.day == DateTime.now().day)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),

              child: showFullMonth
                  ? FilledButton(
                      onPressed: () =>
                          ref.read(showFullMonthProvider.notifier).state =
                              false,
                      child: const Text('Go to today'),
                    )
                  : FilledButton(
                      onPressed: () =>
                          ref.read(showFullMonthProvider.notifier).state = true,
                      child: const Text('Expand view'),
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

          // 1. Filter Waktu (Rentang vs Tanggal/Bulan Spesifik)
          if (isModeRentang && rentangAwal != null && rentangAkhir != null) {
            filteredList = filteredList.where((t) {
              final date = DateTime(t.waktu.year, t.waktu.month, t.waktu.day);
              final start = DateTime(
                rentangAwal.year,
                rentangAwal.month,
                rentangAwal.day,
              );
              final end = DateTime(
                rentangAkhir.year,
                rentangAkhir.month,
                rentangAkhir.day,
              );
              return date.isAfter(start.subtract(const Duration(days: 1))) &&
                  date.isBefore(end.add(const Duration(days: 1)));
            }).toList();
          } else {
            if (!isFilterActive && !showFullMonth) {
              // Jika filter kriteria mati dan expand view mati, tampilkan satu hari
              filteredList = filteredList
                  .where(
                    (t) =>
                        t.waktu.year == selectedDate.year &&
                        t.waktu.month == selectedDate.month &&
                        t.waktu.day == selectedDate.day,
                  )
                  .toList();
            } else {
              // Jika filter kriteria aktif atau expand view aktif, buka cakupan satu bulan
              filteredList = filteredList
                  .where(
                    (t) =>
                        t.waktu.year == selectedDate.year &&
                        t.waktu.month == selectedDate.month,
                  )
                  .toList();
            }
          }

          // 2. Filter Kriteria (Jika aktif)
          if (isFilterActive) {
            if (filterTipe != null) {
              filteredList = filteredList
                  .where((t) => t.tipe == filterTipe)
                  .toList();
            }
            if (filterCatatan.isNotEmpty) {
              final query = filterCatatan.toLowerCase();
              filteredList = filteredList
                  .where((t) => t.catatan.toLowerCase().contains(query))
                  .toList();
            }
            if (filterAkunId != null) {
              filteredList = filteredList
                  .where(
                    (t) =>
                        t.akunSumberId == filterAkunId ||
                        t.akunTujuanId == filterAkunId,
                  )
                  .toList();
            }
            if (filterLabelId != null) {
              filteredList = filteredList.where((t) {
                if (t.labelId == null || t.labelId!.isEmpty) return false;
                final labels = t.labelId!.split(',');
                return labels.contains(filterLabelId);
              }).toList();
            }
            if (filterMinNominal != null) {
              filteredList = filteredList
                  .where((t) => t.nominal >= filterMinNominal)
                  .toList();
            }
            if (filterMaxNominal != null) {
              filteredList = filteredList
                  .where((t) => t.nominal <= filterMaxNominal)
                  .toList();
            }
          }

          filteredList.sort((a, b) => b.waktu.compareTo(a.waktu));

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
              Expanded(
                child: filteredList.isEmpty && (isFilterActive || showFullMonth)
                    ? const Center(
                        child: Text('Tidak ada transaksi yang cocok'),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Deteksi lebar layar untuk mengatur jumlah kolom grid
                          final double lebarLayar = constraints.maxWidth;
                          final int crossAxisCount;

                          if (lebarLayar >= 840) {
                            crossAxisCount = 4; // Layar Desktop
                          } else if (lebarLayar >= 600) {
                            crossAxisCount = 3; // Layar Tablet / Mini-tablet
                          } else if (lebarLayar >= 400) {
                            crossAxisCount = 2;
                          } // Hp horizontal
                          else {
                            crossAxisCount = 1; // Layar Ponsel
                          }
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

                                      Color colorTipe;
                                      String textAkun;

                                      if (t.tipe == TipeTransaksi.pemasukan) {
                                        colorTipe = Colors.green;
                                        textAkun = 'Ke $namaTujuan';
                                      } else if (t.tipe ==
                                          TipeTransaksi.pengeluaran) {
                                        colorTipe = Colors.red;
                                        textAkun = 'Dari $namaSumber';
                                      } else {
                                        colorTipe = Colors.blue;
                                        textAkun = '$namaSumber ➔ $namaTujuan';
                                      }

                                      final bool isTerkunci = isBulanTerkunci(
                                        t.waktu,
                                      );

                                      return Card(
                                        elevation: 0, // Hilangkan bayangan agar outline terlihat bersih
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color: colorTipe, // Warna outline sesuai tipe transaksi
                                            width: 1.5,
                                          ),
                                        ),
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
                                            child: ListTile(
                                              // Properti leading dihapus
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
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                              if (!isFilterActive &&
                                  !showFullMonth &&
                                  filteredList.isEmpty)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.receipt_long,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Belum ada transaksi hari ini',
                                          style: TextStyle(color: Colors.grey),
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

  void _tampilFormFilter(
    List<AkunModel> akunList,
    List<LabelModel> labelList,
    WidgetRef ref,
  ) {
    String tempCatatan = ref.read(filterCatatanProvider);
    String? tempAkunId = ref.read(filterAkunIdProvider);
    String? tempLabelId = ref.read(filterLabelIdProvider);
    TipeTransaksi? tempTipe = ref.read(filterTipeProvider);

    final minVal = ref.read(filterMinNominalProvider);
    final maxVal = ref.read(filterMaxNominalProvider);

    final catatanCtrl = TextEditingController(text: tempCatatan);
    final minCtrl = TextEditingController(
      text: minVal != null ? minVal.toRibuan() : '',
    );
    final maxCtrl = TextEditingController(
      text: maxVal != null ? maxVal.toRibuan() : '',
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
                    ref.read(isFilterActiveProvider.notifier).state = false;
                    ref.read(filterCatatanProvider.notifier).state = '';
                    ref.read(filterAkunIdProvider.notifier).state = null;
                    ref.read(filterLabelIdProvider.notifier).state = null;
                    ref.read(filterMinNominalProvider.notifier).state = null;
                    ref.read(filterMaxNominalProvider.notifier).state = null;
                    ref.read(filterTipeProvider.notifier).state = null;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    // Validasi pengisian Min dan Max
                    if (minCtrl.text.isNotEmpty && maxCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wajib mengisi Max (Rp) jika Min (Rp) diisi',
                          ),
                        ),
                      );
                      return;
                    }
                    if (minCtrl.text.isEmpty && maxCtrl.text.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wajib mengisi Min (Rp) jika Max (Rp) diisi',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final parsedMin = minCtrl.text.isNotEmpty
                        ? double.parse(minCtrl.text.replaceAll('.', ''))
                        : null;
                    final parsedMax = maxCtrl.text.isNotEmpty
                        ? double.parse(maxCtrl.text.replaceAll('.', ''))
                        : null;

                    ref.read(filterCatatanProvider.notifier).state = tempCatatan
                        .trim();
                    ref.read(filterAkunIdProvider.notifier).state = tempAkunId;
                    ref.read(filterLabelIdProvider.notifier).state =
                        tempLabelId;
                    ref.read(filterTipeProvider.notifier).state = tempTipe;
                    ref.read(filterMinNominalProvider.notifier).state =
                        parsedMin;
                    ref.read(filterMaxNominalProvider.notifier).state =
                        parsedMax;

                    ref.read(isFilterActiveProvider.notifier).state =
                        tempCatatan.trim().isNotEmpty ||
                        tempAkunId != null ||
                        tempLabelId != null ||
                        parsedMin != null ||
                        parsedMax != null ||
                        tempTipe != null;
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

  void _tampilFormJumpToDate(
    List<TransaksiModel> listTransaksi,
    WidgetRef ref,
  ) {
    // 1. Baca status terkini untuk pre-fill form
    final currentDate = ref.read(selectedDateProvider);
    final currentIsModeRentang = ref.read(isModeRentangProvider);

    int modePencarian = currentIsModeRentang ? 1 : 0;

    int? selectedYear = currentIsModeRentang ? null : currentDate.year;
    int? selectedMonth = currentIsModeRentang ? null : currentDate.month;
    int? selectedDay = currentIsModeRentang ? null : currentDate.day;

    DateTime? tempStart = ref.read(rentangAwalProvider);
    DateTime? tempEnd = ref.read(rentangAkhirProvider);

    const bulanMap = [
      '',
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

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final availableYears =
                listTransaksi.map((t) => t.waktu.year).toSet().toList()..sort();

            final availableMonths =
                selectedYear == null
                      ? <int>[]
                      : listTransaksi
                            .where((t) => t.waktu.year == selectedYear)
                            .map((t) => t.waktu.month)
                            .toSet()
                            .toList()
                  ..sort();

            final availableDays =
                (selectedYear == null || selectedMonth == null)
                      ? <int>[]
                      : listTransaksi
                            .where(
                              (t) =>
                                  t.waktu.year == selectedYear &&
                                  t.waktu.month == selectedMonth,
                            )
                            .map((t) => t.waktu.day)
                            .toSet()
                            .toList()
                  ..sort();

            if (selectedYear != null &&
                !availableYears.contains(selectedYear)) {
              selectedYear = null;
            }
            if (selectedMonth != null &&
                !availableMonths.contains(selectedMonth)) {
              selectedMonth = null;
            }
            if (selectedDay != null && !availableDays.contains(selectedDay)) {
              selectedDay = null;
            }

            return AlertDialog(
              title: const Text('Pencarian Tanggal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioGroup<int>(
                      groupValue: modePencarian,
                      onChanged: (val) =>
                          setStateDialog(() => modePencarian = val!),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Radio<int>(value: 0),
                              const Text('Tanggal Spesifik'),
                            ],
                          ),
                          Row(
                            children: [
                              Radio<int>(value: 1),
                              const Text('Rentang (Max 30 Hari)'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    if (modePencarian == 0) ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedYear,
                        hint: const Text('Pilih Tahun'),
                        items: availableYears
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setStateDialog(() {
                          selectedYear = val;
                          selectedMonth = null;
                          selectedDay = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: selectedMonth,
                        hint: const Text('Pilih Bulan'),
                        items: availableMonths
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(bulanMap[m]),
                              ),
                            )
                            .toList(),
                        onChanged: availableMonths.isEmpty
                            ? null
                            : (val) => setStateDialog(() {
                                selectedMonth = val;
                                selectedDay = null;
                              }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: selectedDay,
                        hint: const Text('Pilih Tanggal'),
                        items: availableDays
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(d.toString().padLeft(2, '0')),
                              ),
                            )
                            .toList(),
                        onChanged: availableDays.isEmpty
                            ? null
                            : (val) => setStateDialog(() => selectedDay = val),
                      ),
                    ] else ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Tanggal Mulai',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          tempStart != null
                              ? '${tempStart!.day.toString().padLeft(2, '0')} ${bulanMap[tempStart!.month]} ${tempStart!.year}'
                              : 'Pilih tanggal',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: tempStart ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setStateDialog(() => tempStart = date);
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Tanggal Akhir',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          tempEnd != null
                              ? '${tempEnd!.day.toString().padLeft(2, '0')} ${bulanMap[tempEnd!.month]} ${tempEnd!.year}'
                              : 'Pilih tanggal',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: tempEnd ?? tempStart ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setStateDialog(() => tempEnd = date);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    // 2. Simpan nilai ke Provider saat diterapkan
                    if (modePencarian == 0) {
                      if (selectedYear == null ||
                          selectedMonth == null ||
                          selectedDay == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Lengkapi pilihan tahun, bulan, dan tanggal',
                            ),
                          ),
                        );
                        return;
                      }

                      ref.read(selectedDateProvider.notifier).state = DateTime(
                        selectedYear!,
                        selectedMonth!,
                        selectedDay!,
                      );
                      ref.read(isModeRentangProvider.notifier).state = false;
                      ref.read(rentangAwalProvider.notifier).state = null;
                      ref.read(rentangAkhirProvider.notifier).state = null;

                      ref.read(showFullMonthProvider.notifier).state = false;
                      Navigator.pop(dialogContext);
                    } else {
                      if (tempStart == null || tempEnd == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pilih tanggal awal dan akhir'),
                          ),
                        );
                        return;
                      }
                      if (tempEnd!.isBefore(tempStart!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tanggal akhir tidak boleh lebih awal dari tanggal mulai',
                            ),
                          ),
                        );
                        return;
                      }
                      if (tempEnd!.difference(tempStart!).inDays > 30) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rentang maksimal adalah 30 hari'),
                          ),
                        );
                        return;
                      }

                      ref.read(rentangAwalProvider.notifier).state = tempStart;
                      ref.read(rentangAkhirProvider.notifier).state = tempEnd;
                      ref.read(isModeRentangProvider.notifier).state = true;

                      ref.read(showFullMonthProvider.notifier).state = false;
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
