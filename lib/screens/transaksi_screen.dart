import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/transaksi_controller.dart';
import '../models/transaksi_model.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Filter / Jump to Page',
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
          // Hapus List<TransaksiModel> dari parameter ini

          // Lakukan casting eksplisit di dalam blok
          final List<TransaksiModel> listData = List<TransaksiModel>.from(
            transaksiList as Iterable,
          );

          var filteredList = listData;
          if (_filterTanggal != null) {
            filteredList = listData
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
              final TransaksiModel t = filteredList[index]; // Deklarasikan tipe TransaksiModel di sini
              return ListTile(
                title: Text(t.catatan),
                subtitle: Text(t.waktu.toString().split(' ')[0]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.nominal.toIdr(), // Ekstensi ini sekarang akan terbaca tanpa error
                      style: TextStyle(
                        color: t.tipe == TipeTransaksi.pemasukan
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PopupMenuButton<String>(
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
                  ],
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
