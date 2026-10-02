import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/utang_piutang_controller.dart';
import '../models/utang_piutang_model.dart';
import '../controllers/akun_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../models/transaksi_model.dart';
import '../utils/currency_format.dart';
import 'form_utang_piutang.dart';

class UtangScreen extends ConsumerStatefulWidget {
  const UtangScreen({super.key});

  @override
  ConsumerState<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends ConsumerState<UtangScreen> {
  DateTime? _filterTanggal;

  // Variabel untuk fitur pencarian lokal
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(utangPiutangControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Cari pihak atau catatan...',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
              : const Text('Utang & Piutang'),
          actions: [
            // Tombol Pencarian Teks
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    if (_searchController.text.isEmpty) {
                      _isSearching = false;
                    }
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Cari Data',
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),

            // Tombol Filter Tanggal
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

            // 2. Terapkan filter pencarian teks (pencarian lokal yang ringan)
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              filteredList = filteredList.where((e) {
                return e.pihakTerkait.toLowerCase().contains(query) ||
                    e.catatan.toLowerCase().contains(query);
              }).toList();
            }

            final listUtang = filteredList
                .where((e) => e.tipe == TipeUtangPiutang.utang)
                .toList();
            final listPiutang = filteredList
                .where((e) => e.tipe == TipeUtangPiutang.piutang)
                .toList();

            return TabBarView(
              children: [
                _buildList(listUtang, context, ref),
                _buildList(listPiutang, context, ref),
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
  ) {
    if (data.isEmpty) return const Center(child: Text('Data kosong'));

    final akunList = ref.watch(akunControllerProvider).value ?? [];
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

        String namaAkun = 'Tidak diketahui';
        if (item.akunId != null) {
          try {
            namaAkun = akunList.firstWhere((a) => a.id == item.akunId).nama;
          } catch (_) {
            namaAkun = 'Akun terhapus';
          }
        }

        final tglBuat = item.waktu;
        final tglJatuhTempo = item.tenggatWaktu;

        final formatTglBuat =
            '${tglBuat.day.toString().padLeft(2, '0')} ${bulanMap[tglBuat.month]} ${tglBuat.year}';
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
                    if (isUtang) ...[
                      Text(
                        'Dana ke $namaAkun',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text('Harus bayar ke ${item.pihakTerkait}'),
                    ] else ...[
                      Text(
                        'Dana dari $namaAkun',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text('Harus dibayar oleh ${item.pihakTerkait}'),
                    ],

                    const SizedBox(height: 6),
                    Text(item.catatan, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 13,
                                color: Colors.yellow[900],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Dibuat: $formatTglBuat',
                                style: TextStyle(
                                  color: Colors.yellow[900],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
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
                        ref
                            .read(utangPiutangControllerProvider.notifier)
                            .hapusUtangPiutang(item.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              onTap: () {
                if (!item.isLunas) {
                  _tampilFormPelunasan(context, ref, item);
                }
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final akunState = ref.watch(akunControllerProvider);
            return AlertDialog(
              title: Text(isUtang ? 'Pelunasan Utang' : 'Pelunasan Piutang'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nominal: ${item.nominal.toIdr()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  akunState.maybeWhen(
                    data: (akunList) => DropdownButtonFormField<String>(
                      initialValue: selectedAkunId,
                      hint: Text(
                        isUtang ? 'Akun untuk Membayar' : 'Akun untuk Menerima',
                      ),
                      items: akunList
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.nama),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedAkunId = val),
                    ),
                    orElse: () => const CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal Pelunasan'),
                    subtitle: Text(selectedDate.toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedAkunId == null) return;

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
}
