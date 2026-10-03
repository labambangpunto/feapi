import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/utang_piutang_controller.dart';
import '../models/utang_piutang_model.dart';
import '../controllers/akun_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../models/transaksi_model.dart';
import '../models/akun_model.dart'; // Tambahan untuk tipe AkunModel
import '../utils/currency_format.dart';
import '../utils/currency_formatter.dart'; // Tambahan untuk form nominal
import 'form_utang_piutang.dart';

class UtangScreen extends ConsumerStatefulWidget {
  const UtangScreen({super.key});

  @override
  ConsumerState<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends ConsumerState<UtangScreen> {
  DateTime? _filterTanggal;

  // Variabel untuk filter pencarian tingkat lanjut
  bool _isFilterActive = false;
  String _filterKataKunci = '';
  String? _filterAkunId;
  bool? _filterStatusLunas;
  double? _filterMinNominal;
  double? _filterMaxNominal;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(utangPiutangControllerProvider);
    final akunList = ref.watch(akunControllerProvider).value ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Utang & Piutang'),
          actions: [
            if (_isFilterActive)
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                tooltip: 'Hapus Filter',
                onPressed: () {
                  setState(() {
                    _isFilterActive = false;
                    _filterKataKunci = '';
                    _filterAkunId = null;
                    _filterStatusLunas = null;
                    _filterMinNominal = null;
                    _filterMaxNominal = null;
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Cari / Filter',
                onPressed: () => _tampilFormFilter(akunList),
              ),

            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Filter Tanggal',
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _filterTanggal = date);
              },
            ),
            if (_filterTanggal != null)
              IconButton(
                icon: const Icon(Icons.event_busy),
                tooltip: 'Hapus Filter Tanggal',
                onPressed: () => setState(() => _filterTanggal = null),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Utang'),
              Tab(text: 'Piutang'),
            ],
          ),
        ),
        body: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (listData) {
            var filteredList = listData;

            // 1. Terapkan filter tanggal (jika ada)
            if (_filterTanggal != null) {
              filteredList = filteredList
                  .where(
                    (e) =>
                        e.waktu.year == _filterTanggal!.year &&
                        e.waktu.month == _filterTanggal!.month &&
                        e.waktu.day == _filterTanggal!.day,
                  )
                  .toList();
            }

            // 2. Terapkan filter pencarian lanjutan
            if (_isFilterActive) {
              if (_filterStatusLunas != null) {
                filteredList = filteredList
                    .where((e) => e.isLunas == _filterStatusLunas)
                    .toList();
              }

              if (_filterKataKunci.isNotEmpty) {
                final query = _filterKataKunci.toLowerCase();
                filteredList = filteredList.where((e) {
                  return e.pihakTerkait.toLowerCase().contains(query) ||
                      e.catatan.toLowerCase().contains(query);
                }).toList();
              }

              if (_filterAkunId != null) {
                filteredList = filteredList
                    .where((e) => e.akunId == _filterAkunId)
                    .toList();
              }

              if (_filterMinNominal != null) {
                filteredList = filteredList
                    .where((e) => e.nominal >= _filterMinNominal!)
                    .toList();
              }

              if (_filterMaxNominal != null) {
                filteredList = filteredList
                    .where((e) => e.nominal <= _filterMaxNominal!)
                    .toList();
              }
            }

            final listUtang = filteredList
                .where((e) => e.tipe == TipeUtangPiutang.utang)
                .toList();
            final listPiutang = filteredList
                .where((e) => e.tipe == TipeUtangPiutang.piutang)
                .toList();

            return TabBarView(
              children: [
                _buildList(listUtang, context, ref, akunList),
                _buildList(listPiutang, context, ref, akunList),
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
                    leading: const Icon(
                      Icons.arrow_downward,
                      color: Colors.red,
                    ),
                    title: const Text('Tambah Utang'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FormUtangPiutangScreen(
                            tipe: TipeUtangPiutang.utang,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.arrow_upward,
                      color: Colors.green,
                    ),
                    title: const Text('Tambah Piutang'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FormUtangPiutangScreen(
                            tipe: TipeUtangPiutang.piutang,
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
      ),
    );
  }

  Widget _buildList(
    List<UtangPiutangModel> data,
    BuildContext context,
    WidgetRef ref,
    List<AkunModel> akunList,
  ) {
    if (data.isEmpty) {
      return const Center(child: Text('Tidak ada data yang cocok'));
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

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final isUtang = item.tipe == TipeUtangPiutang.utang;

        final tglJatuhTempo = item.tenggatWaktu;
        final formatJatuhTempo =
            '${tglJatuhTempo.day.toString().padLeft(2, '0')} ${bulanMap[tglJatuhTempo.month]} ${tglJatuhTempo.year}';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                item.nominal.toIdr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: item.isLunas
                      ? Colors.grey
                      : (isUtang ? Colors.green : Colors.red),
                  decoration: item.isLunas ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.catatan.isNotEmpty) ...[
                      Text(
                        item.catatan,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        border: Border.all(
                          color: Colors.yellow[700]!,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 14,
                            color: Colors.yellow[900],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Jatuh tempo: $formatJatuhTempo',
                            style: TextStyle(
                              color: Colors.yellow[900],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.isLunas)
                    const Icon(Icons.check_circle, color: Colors.green),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FormUtangPiutangScreen(
                              tipe: item.tipe,
                              dataEdit: item,
                            ),
                          ),
                        );
                      } else if (value == 'hapus') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Konfirmasi Hapus'),
                            content: Text(
                              'Apakah Anda yakin ingin menghapus data ${isUtang ? "utang" : "piutang"} ini?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  ref
                                      .read(
                                        utangPiutangControllerProvider.notifier,
                                      )
                                      .hapusUtangPiutang(item.id);
                                  Navigator.pop(ctx);
                                },
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      if (!item.isLunas)
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              onTap: () {
                // Hapus kondisi if (!item.isLunas) agar bisa selalu diklik
                _tampilFormPelunasan(context, ref, item);
              },
            ),
          ),
        );
      },
    );
  }

  void _tampilFormPelunasan(
    BuildContext context,
    WidgetRef ref,
    UtangPiutangModel item,
  ) {
    String? selectedAkunId;
    DateTime selectedDate = DateTime.now();
    final isUtang = item.tipe == TipeUtangPiutang.utang;

    final akunList = ref.read(akunControllerProvider).value ?? [];
    String namaAkunAwal = '-';
    if (item.akunId != null) {
      try {
        namaAkunAwal = akunList.firstWhere((a) => a.id == item.akunId).nama;
      } catch (_) {
        namaAkunAwal = 'Akun terhapus';
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
    final tglBuat =
        '${item.waktu.day.toString().padLeft(2, '0')} ${bulanMap[item.waktu.month]} ${item.waktu.year}';
    final tglJatuhTempo =
        '${item.tenggatWaktu.day.toString().padLeft(2, '0')} ${bulanMap[item.tenggatWaktu.month]} ${item.tenggatWaktu.year}';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final akunState = ref.watch(akunControllerProvider);
            return AlertDialog(
              // Sesuaikan judul jika sudah lunas
              title: Text(
                item.isLunas
                    ? (isUtang ? 'Detail Utang' : 'Detail Piutang')
                    : (isUtang ? 'Pelunasan Utang' : 'Pelunasan Piutang'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nominal.toIdr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isUtang ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isUtang
                                ? 'Dana masuk ke: $namaAkunAwal'
                                : 'Dana keluar dari: $namaAkunAwal',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            isUtang
                                ? 'Berutang kepada: ${item.pihakTerkait}'
                                : 'Diutangkan kepada: ${item.pihakTerkait}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (item.catatan.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Catatan: ${item.catatan}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          const Divider(),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Dibuat: $tglBuat',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 12,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Jatuh tempo: $tglJatuhTempo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Sembunyikan form pelunasan jika sudah lunas
                    if (!item.isLunas) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Form Pelunasan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      akunState.maybeWhen(
                        data: (listAkun) => DropdownButtonFormField<String>(
                          initialValue: selectedAkunId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: Text(
                            isUtang
                                ? 'Akun untuk Membayar'
                                : 'Akun untuk Menerima',
                          ),
                          items: listAkun
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(a.nama),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedAkunId = val),
                        ),
                        orElse: () => const CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Tanggal Pelunasan',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${selectedDate.day.toString().padLeft(2, '0')} ${bulanMap[selectedDate.month]} ${selectedDate.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) setState(() => selectedDate = date);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(item.isLunas ? 'Tutup' : 'Batal'),
                ),
                // Sembunyikan tombol "Lunas" jika sudah lunas
                if (!item.isLunas)
                  ElevatedButton(
                    onPressed: () {
                      if (selectedAkunId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Pilih akun pelunasan terlebih dahulu!',
                            ),
                          ),
                        );
                        return;
                      }

                      final updatedItem = UtangPiutangModel(
                        id: item.id,
                        tipe: item.tipe,
                        nominal: item.nominal,
                        pihakTerkait: item.pihakTerkait,
                        akunId: item.akunId,
                        waktu: item.waktu,
                        tenggatWaktu: item.tenggatWaktu,
                        catatan: item.catatan,
                        isLunas: true,
                      );
                      ref
                          .read(utangPiutangControllerProvider.notifier)
                          .updateUtangPiutang(updatedItem);

                      final transaksi = TransaksiModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        tipe: isUtang
                            ? TipeTransaksi.pengeluaran
                            : TipeTransaksi.pemasukan,
                        nominal: item.nominal,
                        akunSumberId: isUtang ? selectedAkunId : null,
                        akunTujuanId: isUtang ? null : selectedAkunId,
                        labelId: isUtang ? 'label_utang' : 'label_piutang',
                        waktu: selectedDate,
                        catatan:
                            'Pelunasan ${isUtang ? "Utang ke" : "Piutang dari"} ${item.pihakTerkait}',
                      );
                      ref
                          .read(transaksiControllerProvider.notifier)
                          .tambahTransaksi(transaksi);

                      Navigator.pop(context);
                    },
                    child: const Text('Lunas'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _tampilFormFilter(List<AkunModel> akunList) {
    String tempKataKunci = _filterKataKunci;
    String? tempAkunId = _filterAkunId;
    bool? tempStatusLunas = _filterStatusLunas;

    final kataCtrl = TextEditingController(text: tempKataKunci);
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
                      'Filter Utang & Piutang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<bool?>(
                      initialValue: tempStatusLunas,
                      decoration: const InputDecoration(
                        labelText: 'Status Pelunasan',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Semua Status'),
                        ),
                        DropdownMenuItem(value: true, child: Text('Lunas')),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Belum Lunas'),
                        ),
                      ],
                      onChanged: (val) =>
                          setStateSheet(() => tempStatusLunas = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: kataCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pihak Terkait atau Catatan',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) => tempKataKunci = val,
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
                                _filterKataKunci = '';
                                _filterAkunId = null;
                                _filterStatusLunas = null;
                                _filterMinNominal = null;
                                _filterMaxNominal = null;
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
                                _filterKataKunci = tempKataKunci.trim();
                                _filterAkunId = tempAkunId;
                                _filterStatusLunas = tempStatusLunas;

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
                                    _filterKataKunci.isNotEmpty ||
                                    _filterAkunId != null ||
                                    _filterStatusLunas != null ||
                                    _filterMinNominal != null ||
                                    _filterMaxNominal != null;
                              });
                            },
                            child: const Text('Terapkan Filter'),
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
