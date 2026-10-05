import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controllers/summary_provider.dart';
import '../controllers/utang_piutang_controller.dart';
import '../models/utang_piutang_model.dart';
import '../utils/currency_format.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    final utangState = ref.watch(utangPiutangControllerProvider);

    double totalUtangBelumLunas = 0;
    double totalPiutangBelumLunas = 0;

    if (utangState.hasValue) {
      for (var item in utangState.value!) {
        if (!item.isLunas) {
          if (item.tipe == TipeUtangPiutang.utang) {
            totalUtangBelumLunas += item.nominal;
          } else {
            totalPiutangBelumLunas += item.nominal;
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Halo, Selamat Datang!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text(
            'Arus Kas Transaksi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Pemasukan',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.totalPemasukan.toIdr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Pengeluaran',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary.totalPengeluaran.toIdr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
            'Tagihan Berjalan (Belum Lunas)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Utang Saya',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalUtangBelumLunas.toIdr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Piutang Saya',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalPiutangBelumLunas.toIdr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Grafik Pemasukan vs Pengeluaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child:
                (summary.totalPemasukan == 0 && summary.totalPengeluaran == 0)
                ? const Center(child: Text('Belum ada data transaksi reguler'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: summary.totalPemasukan,
                          title: 'Masuk\n${summary.totalPemasukan.toIdr()}',
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
                          title: 'Keluar\n${summary.totalPengeluaran.toIdr()}',
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
