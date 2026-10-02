import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/transaksi_controller.dart';
import '../controllers/akun_controller.dart';
import '../controllers/label_controller.dart';
import '../models/transaksi_model.dart';
import '../models/akun_model.dart';
import '../utils/currency_format.dart';

import 'form_transaksi.dart';

class TransaksiScreen extends ConsumerStatefulWidget {
  const TransaksiScreen({super.key});

  @override
  ConsumerState<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends ConsumerState<TransaksiScreen> {
  final ScrollController _scrollController = ScrollController();
  DateTime? _filterTanggal;

  @override
  Widget build(BuildContext context) {
    final transaksiState = ref.watch(transaksiControllerProvider);
    final akunList = ref.watch(akunControllerProvider).value ?? [];
    final labelList = ref.watch(labelControllerProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
              icon: const Icon(Icons.clear),
              tooltip: 'Hapus Filter',
              onPressed: () => setState(() => _filterTanggal = null),
            ),
        ],
      ),
      body: transaksiState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (transaksiList) {
          var filteredList = transaksiList;
          if (_filterTanggal != null) {
            filteredList = transaksiList
                .where(
                  (t) =>
                      t.waktu.year == _filterTanggal!.year &&
                      t.waktu.month == _filterTanggal!.month &&
                      t.waktu.day == _filterTanggal!.day,
                )
                .toList();
          }

          if (filteredList.isEmpty) {
            return const Center(
              child: Text('Tidak ada transaksi pada filter ini'),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final TransaksiModel t = filteredList[index];

              // Cari nama sumber (menggunakan orElse untuk menghindari pelemparan StateError)
              String namaSumber = '-';
              if (t.akunSumberId != null) {
                namaSumber = akunList
                    .firstWhere(
                      (a) => a.id == t.akunSumberId,
                      orElse: () => AkunModel(id: '', nama: 'Akun terhapus'),
                    )
                    .nama;
              }

              // Cari nama tujuan
              String namaTujuan = '-';
              if (t.akunTujuanId != null) {
                namaTujuan = akunList
                    .firstWhere(
                      (a) => a.id == t.akunTujuanId,
                      orElse: () => AkunModel(id: '', nama: 'Akun terhapus'),
                    )
                    .nama;
              }

              // Cari nama label
              List<String> namaLabels = [];
              if (t.labelId != null && t.labelId!.isNotEmpty) {
                final labelIds = t.labelId!.split(',');
                for (var id in labelIds) {
                  try {
                    namaLabels.add(
                      labelList.firstWhere((l) => l.id == id).nama,
                    );
                  } catch (_) {
                    namaLabels.add('Label terhapus');
                  }
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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

                          if (t.tipe == TipeTransaksi.pengeluaran) ...[
                            // Menghapus penggunaan ?? pada properti non-nullable
                            Text('Kuantitas: ${t.kuantitas}'),
                            if (t.biayaTambahan != null && t.biayaTambahan! > 0)
                              Text(
                                'Biaya Tambahan: ${t.biayaTambahan!.toIdr()}',
                              ),
                            Text('Dari $namaSumber'),
                          ] else if (t.tipe == TipeTransaksi.pemasukan) ...[
                            Text('Ke $namaTujuan'),
                          ] else if (t.tipe == TipeTransaksi.transfer) ...[
                            if (t.biayaTambahan != null && t.biayaTambahan! > 0)
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
                                      mainAxisSize: MainAxisSize.min,
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
                              .read(transaksiControllerProvider.notifier)
                              .hapusTransaksi(t.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
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
}
