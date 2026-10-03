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
  TipeTransaksi? _filterTipe; // Variabel baru untuk jenis transaksi

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
                  _filterTipe = null; // Reset filter jenis transaksi
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
          // Fungsi helper untuk menerjemahkan ID menjadi Nama
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
            // Mode Normal: Filter HANYA pada hari yang dipilih
            filteredList = filteredList
                .where(
                  (t) =>
                      t.waktu.year == _selectedDate.year &&
                      t.waktu.month == _selectedDate.month &&
                      t.waktu.day == _selectedDate.day,
                )
                .toList();
          } else {
            // Mode Pencarian: Filter pada SATU BULAN yang dipilih
            filteredList = filteredList
                .where(
                  (t) =>
                      t.waktu.year == _selectedDate.year &&
                      t.waktu.month == _selectedDate.month,
                )
                .toList();

            // Eksekusi Parameter Filter
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
              // Header Penunjuk Waktu & Status Filter
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

              // Daftar Transaksi
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

                          String namaSumber = getAkunName(t.akunSumberId);
                          String namaTujuan = getAkunName(t.akunTujuanId);
                          List<String> namaLabels = getLabelNames(t.labelId);

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  t.nominal.toIdr(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: t.tipe == TipeTransaksi.pemasukan
                                        ? Colors.green
                                        : (t.tipe == TipeTransaksi.pengeluaran
                                              ? Colors.red
                                              : Colors.blue),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.catatan,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      if (t.tipe ==
                                          TipeTransaksi.pengeluaran) ...[
                                        Text('Kuantitas: ${t.kuantitas}'),
                                        if (t.biayaTambahan != null &&
                                            t.biayaTambahan! > 0)
                                          Text(
                                            'Biaya Tambahan: ${t.biayaTambahan!.toIdr()}',
                                          ),
                                        Text('Dari $namaSumber'),
                                      ] else if (t.tipe ==
                                          TipeTransaksi.pemasukan) ...[
                                        Text('Ke $namaTujuan'),
                                      ] else if (t.tipe ==
                                          TipeTransaksi.transfer) ...[
                                        if (t.biayaTambahan != null &&
                                            t.biayaTambahan! > 0)
                                          Text(
                                            'Biaya Tambahan: ${t.biayaTambahan!.toIdr()}',
                                          ),
                                        Text('Dari $namaSumber ke $namaTujuan'),
                                      ],

                                      if (namaLabels.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: namaLabels
                                              .map(
                                                (nl) => Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.label_outline,
                                                      size: 14,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      nl,
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
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
                                      ref
                                          .read(
                                            transaksiControllerProvider
                                                .notifier,
                                          )
                                          .hapusTransaksi(t.id);
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

  void _tampilFormFilter(List<AkunModel> akunList, List<LabelModel> labelList) {
    String tempCatatan = _filterCatatan;
    String? tempAkunId = _filterAkunId;
    String? tempLabelId = _filterLabelId;
    TipeTransaksi? tempTipe = _filterTipe;

    // Inisialisasi controller dengan nilai yang sudah ada sebelumnya (jika ada)
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

                                // Aktifkan status filter jika ada minimal satu field yang diisi
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
