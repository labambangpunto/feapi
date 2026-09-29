import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controllers/summary_provider.dart';
import '../controllers/akun_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    final akunState = ref.watch(akunControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Halo, Selamat Datang!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Saldo', style: TextStyle(fontSize: 16)),
                  Text(
                    'Rp ${summary.totalSaldo}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.green.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Pemasukan'),
                        Text(
                          'Rp ${summary.totalPemasukan}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Pengeluaran'),
                        Text(
                          'Rp ${summary.totalPengeluaran}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Saldo Masing-masing Akun',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          akunState.maybeWhen(
            data: (akunList) {
              if (akunList.isEmpty) return const Text('Belum ada akun.');
              return Column(
                children: akunList.map((akun) {
                  final saldoRiil = summary.saldoPerAkun[akun.id] ?? 0;
                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text(akun.nama),
                    trailing: Text(
                      'Rp $saldoRiil',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              );
            },
            orElse: () => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Grafik Pemasukan vs Pengeluaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child:
                (summary.totalPemasukan == 0 && summary.totalPengeluaran == 0)
                ? const Center(child: Text('Belum ada data transaksi'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: summary.totalPemasukan,
                          title: 'Masuk\nRp ${summary.totalPemasukan}',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.red,
                          value: summary.totalPengeluaran,
                          title: 'Keluar\nRp ${summary.totalPengeluaran}',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
