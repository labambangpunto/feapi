import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/transaksi_controller.dart';
import '../controllers/akun_controller.dart';
import '../controllers/label_controller.dart';
import '../models/transaksi_model.dart';
import '../models/akun_model.dart';
import '../models/label_model.dart';
import '../utils/currency_format.dart';
import '../utils/currency_formatter.dart';

import 'form_transaksi.dart';

class TransaksiScreen extends ConsumerStatefulWidget {
  const TransaksiScreen({super.key});

  @override
  ConsumerState<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends ConsumerState<TransaksiScreen> {
  final ScrollController _scrollController = ScrollController();

  // Tanggal default adalah hari ini
  DateTime _selectedDate = DateTime.now();

  // Variabel untuk filter pencarian tingkat lanjut
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Transaksi'),
        actions: [
          if (_isFilterActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Hapus Filter',
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
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Cari / Filter',
              onPressed: () => _tampilFormFilter(akunList, labelList),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Jump to Date',
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
        ],
      ),
      body: transaksiState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (transaksiList) {
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
                      _isFilterActive
                          ? 'Pencarian di bulan: $displayMonth'
                          : 'Transaksi tanggal: $displayDate',
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
                child: filteredList.isEmpty
                    ? const Center(
                        child: Text('Tidak ada transaksi yang cocok'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final TransaksiModel t = filteredList[index];

                          // Tambahkan kalkulasi nominal final
                          final double totalNominal =
                              (t.nominal * t.kuantitas) +
                              (t.biayaTambahan ?? 0);

                          String namaSumber = getAkunName(t.akunSumberId);
                          String namaTujuan = getAkunName(t.akunTujuanId);
                          List<String> namaLabels = getLabelNames(t.labelId);

                          // Menentukan ikon, warna, dan teks akun yang disederhanakan
                          IconData iconTipe;
                          Color colorTipe;
                          String textAkun;

                          if (t.tipe == TipeTransaksi.pemasukan) {
                            iconTipe = Icons.arrow_downward;
                            colorTipe = Colors.green;
                            textAkun = 'Ke $namaTujuan';
                          } else if (t.tipe == TipeTransaksi.pengeluaran) {
                            iconTipe = Icons.arrow_upward;
                            colorTipe = Colors.red;
                            textAkun = 'Dari $namaSumber';
                          } else {
                            iconTipe = Icons.swap_horiz;
                            colorTipe = Colors.blue;
                            textAkun = '$namaSumber ➔ $namaTujuan';
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colorTipe.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Icon(iconTipe, color: colorTipe),
                                ),
                                title: Text(
                                  totalNominal
                                      .toIdr(), // Gunakan totalNominal di sini
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: colorTipe,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.catatan,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        textAkun,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FormTransaksiScreen(
                                            tipeTransaksi: t.tipe,
                                            dataEdit: t,
                                          ),
                                        ),
                                      );
                                    } else if (value == 'hapus') {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Konfirmasi Hapus'),
                                          content: const Text(
                                            'Apakah Anda yakin ingin menghapus transaksi ini?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('Batal'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              onPressed: () {
                                                ref
                                                    .read(
                                                      transaksiControllerProvider
                                                          .notifier,
                                                    )
                                                    .hapusTransaksi(t.id);
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text(
                                                'Hapus',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'hapus',
                                      child: Text('Hapus'),
                                    ),
                                  ],
                                ),
                                onTap: () => _tampilSummaryTransaksi(
                                  context,
                                  t,
                                  namaSumber,
                                  namaTujuan,
                                  namaLabels,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.arrow_upward, color: Colors.red),
                  title: const Text('Pengeluaran'),
                  onTap: () {
                    Navigator.pop(context);
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
                    Navigator.pop(context);
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
                    Navigator.pop(context);
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
        child: const Icon(Icons.add),
      ),
    );
  }

  void _tampilSummaryTransaksi(
    BuildContext context,
    TransaksiModel t,
    String namaSumber,
    String namaTujuan,
    List<String> namaLabels,
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detail Transaksi'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                totalNominal.toIdr(), // Gunakan totalNominal di sini
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isPemasukan
                      ? Colors.green
                      : (isPengeluaran ? Colors.red : Colors.blue),
                ),
              ),
              const SizedBox(height: 12),

              if (isPengeluaran) ...[
                Text('Kuantitas: ${t.kuantitas}'),
                if (t.biayaTambahan != null && t.biayaTambahan! > 0)
                  Text('Biaya Tambahan: ${t.biayaTambahan!.toIdr()}'),
                const SizedBox(height: 4),
                Text(
                  'Sumber dana: $namaSumber',
                  style: const TextStyle(color: Colors.black87),
                ),
              ] else if (isPemasukan) ...[
                Text(
                  'Tujuan dana: $namaTujuan',
                  style: const TextStyle(color: Colors.black87),
                ),
              ] else if (isTransfer) ...[
                if (t.biayaTambahan != null && t.biayaTambahan! > 0)
                  Text('Biaya Tambahan: ${t.biayaTambahan!.toIdr()}'),
                const SizedBox(height: 4),
                Text(
                  'Dari: $namaSumber',
                  style: const TextStyle(color: Colors.black87),
                ),
                Text(
                  'Ke: $namaTujuan',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tglStr,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
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
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Transaksi Tingkat Lanjut',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TipeTransaksi?>(
                      initialValue: tempTipe,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Transaksi',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Semua Jenis'),
                        ),
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
                      onChanged: (val) => setStateSheet(() => tempTipe = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: catatanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kata Kunci (Catatan)',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) => tempCatatan = val,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tempAkunId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Akun Terkait',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Semua Akun'),
                        ),
                        ...akunList.map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.nama),
                          ),
                        ),
                      ],
                      onChanged: (val) => setStateSheet(() => tempAkunId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tempLabelId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Label',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Semua Label'),
                        ),
                        ...labelList.map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.nama),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setStateSheet(() => tempLabelId = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Nominal Min (Rp)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Nominal Max (Rp)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
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
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _filterCatatan = tempCatatan.trim();
                                _filterAkunId = tempAkunId;
                                _filterLabelId = tempLabelId;
                                _filterTipe = tempTipe;

                                _filterMinNominal = minCtrl.text.isNotEmpty
                                    ? double.parse(
                                        minCtrl.text.replaceAll('.', ''),
                                      )
                                    : null;
                                _filterMaxNominal = maxCtrl.text.isNotEmpty
                                    ? double.parse(
                                        maxCtrl.text.replaceAll('.', ''),
                                      )
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
                            child: const Text('Cari Data'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
