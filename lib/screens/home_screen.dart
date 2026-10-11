import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controllers/transaksi_controller.dart';
import '../models/transaksi_model.dart';
import '../controllers/utang_piutang_controller.dart';
import '../models/utang_piutang_model.dart';
import '../utils/currency_format.dart';
import 'atur_screen.dart';

// Komponen lencana (badge) kustom untuk Pie Chart (mengadaptasi pie_chart_sample3)
class _Badge extends StatelessWidget {
  const _Badge(
    this.icon, {
    required this.size,
    required this.borderColor,
    required this.backgroundColor,
  });
  final IconData icon;
  final double size;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Icon(icon, color: Colors.white, size: size * .5),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Variabel untuk menyimpan status filter (Default: 1 Bulan)
  String _filterWaktu = '1 Bulan';
  int _touchedPieIndex = -1; // Status interaksi Pie Chart

  @override
  Widget build(BuildContext context) {
    // Pantau langsung transaksi untuk difilter secara lokal
    final transaksiState = ref.watch(transaksiControllerProvider);
    final utangState = ref.watch(utangPiutangControllerProvider);
    final profilAsync = ref.watch(profilProvider);

    // Ambil nama dari profil, gunakan 'Pengguna' jika kosong
    final nama = profilAsync.value?['nama']?.isNotEmpty == true
        ? profilAsync.value!['nama']
        : 'Pengguna';

    // Logika sapaan berdasarkan waktu
    final hour = DateTime.now().hour;
    final random = Random(hour);
    List<String> greetings;

    if (hour >= 5 && hour < 11) {
      greetings = [
        'Selamat pagi, $nama\nYuk, catat sarapanmu.',
        'Pagi, $nama\nCek anggaranmu dulu ya.',
        'Selamat pagi, $nama\nCatat transaksi kemarin yuk.',
      ];
    } else if (hour >= 11 && hour < 15) {
      greetings = [
        'Selamat siang, $nama\nSudah catat makan siang?',
        'Siang, $nama\nYuk, cek sisa anggaranmu.',
        'Selamat siang, $nama\nJangan ada yang terlewat ya.',
      ];
    } else if (hour >= 15 && hour < 18) {
      greetings = [
        'Selamat sore, $nama\nYuk, rekap hari ini.',
        'Sore, $nama\nSemua pengeluaran sudah tercatat?',
        'Selamat sore, $nama\nSaatnya cek catatanmu.',
      ];
    } else {
      greetings = [
        'Selamat malam, $nama\nCatat transaksi terakhirmu yuk.',
        'Malam, $nama\nYuk, tinjau pengeluaran hari ini.',
        'Selamat malam, $nama\nTerima kasih sudah disiplin mencatat.',
      ];
    }

    final sapaan = greetings[random.nextInt(greetings.length)];

    // LOGIKA PERHITUNGAN FILTER ARUS KAS & DATA GRAFIK
    double totalPemasukan = 0;
    double totalPengeluaran = 0;
    double totalTransfer = 0;
    final now = DateTime.now();

    Map<int, double> mapPemasukan = {};
    Map<int, double> mapPengeluaran = {};
    Map<int, double> mapTransfer = {};

    int minX = 0;
    int maxX = 0;
    if (_filterWaktu == '1 Hari') {
      minX = 0;
      maxX = 23;
    } else if (_filterWaktu == '1 Minggu') {
      minX = 1;
      maxX = 7;
    } else if (_filterWaktu == '1 Bulan') {
      minX = 1;
      maxX = DateTime(now.year, now.month + 1, 0).day;
    }

    for (int i = minX; i <= maxX; i++) {
      mapPemasukan[i] = 0;
      mapPengeluaran[i] = 0;
      mapTransfer[i] = 0;
    }

    if (transaksiState.hasValue) {
      for (var t in transaksiState.value!) {
        bool isIncluded = false;
        int xKey = 0;

        if (_filterWaktu == '1 Hari') {
          isIncluded =
              t.waktu.year == now.year &&
              t.waktu.month == now.month &&
              t.waktu.day == now.day;
          xKey = t.waktu.hour;
        } else if (_filterWaktu == '1 Minggu') {
          // Menghitung transaksi di minggu kalender yang sama (Senin - saat ini)
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final sDate = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          final tDate = DateTime(t.waktu.year, t.waktu.month, t.waktu.day);
          isIncluded =
              tDate.isAfter(sDate.subtract(const Duration(days: 1))) &&
              tDate.isBefore(
                DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).add(const Duration(days: 1)),
              );
          xKey = t.waktu.weekday;
        } else if (_filterWaktu == '1 Bulan') {
          isIncluded = t.waktu.year == now.year && t.waktu.month == now.month;
          xKey = t.waktu.day;
        }

        if (isIncluded) {
          final nominal = (t.nominal * t.kuantitas) + (t.biayaTambahan ?? 0);
          if (t.tipe == TipeTransaksi.pemasukan) {
            totalPemasukan += nominal;
            mapPemasukan[xKey] = (mapPemasukan[xKey] ?? 0) + nominal;
          } else if (t.tipe == TipeTransaksi.pengeluaran) {
            totalPengeluaran += nominal;
            mapPengeluaran[xKey] = (mapPengeluaran[xKey] ?? 0) + nominal;
          } else if (t.tipe == TipeTransaksi.transfer) {
            totalTransfer += nominal; // Tambahkan baris ini
            mapTransfer[xKey] = (mapTransfer[xKey] ?? 0) + nominal;
          }
        }
      }
    }

    final pemasukanSpots = mapPemasukan.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final pengeluaranSpots = mapPengeluaran.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final transferSpots = mapTransfer.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    pemasukanSpots.sort((a, b) => a.x.compareTo(b.x));
    pengeluaranSpots.sort((a, b) => a.x.compareTo(b.x));
    transferSpots.sort((a, b) => a.x.compareTo(b.x));

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              sapaan,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Header dengan Komponen Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Arus Kas Transaksi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                DropdownButton<String>(
                  value: _filterWaktu,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: '1 Hari', child: Text('Hari Ini')),
                    DropdownMenuItem(
                      value: '1 Minggu',
                      child: Text('Minggu Ini'),
                    ),
                    DropdownMenuItem(
                      value: '1 Bulan',
                      child: Text('Bulan Ini'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _filterWaktu = val);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
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
                            totalPemasukan.toIdr(),
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
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
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
                            totalPengeluaran.toIdr(),
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
                            'Utang',
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
                            'Piutang',
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

            // --- 1. PIE CHART KOMPOSISI ---
            _buildPieChart(totalPemasukan, totalPengeluaran, totalTransfer),

            // --- 2. LINE CHART PENGELUARAN ---
            _buildLineChart(
              title: 'Tren Pengeluaran',
              spots: pengeluaranSpots,
              color: Colors.red,
              minX: minX,
              maxX: maxX,
              filterWaktu: _filterWaktu,
            ),

            // --- 3. LINE CHART PEMASUKAN ---
            _buildLineChart(
              title: 'Tren Pemasukan',
              spots: pemasukanSpots,
              color: Colors.green,
              minX: minX,
              maxX: maxX,
              filterWaktu: _filterWaktu,
            ),

            // --- 4. LINE CHART TRANSFER ---
            _buildLineChart(
              title: 'Tren Transfer Antarakun',
              spots: transferSpots,
              color: Colors.blue,
              minX: minX,
              maxX: maxX,
              filterWaktu: _filterWaktu,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(
    double totalPemasukan,
    double totalPengeluaran,
    double totalTransfer,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Komposisi Arus Kas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child:
                  (totalPemasukan == 0 &&
                      totalPengeluaran == 0 &&
                      totalTransfer == 0)
                  ? const Center(
                      child: Text('Belum ada data transaksi di periode ini'),
                    )
                  : PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedPieIndex = -1;
                                    return;
                                  }
                                  _touchedPieIndex = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _showingSections(
                          totalPemasukan,
                          totalPengeluaran,
                          totalTransfer,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections(
    double totalPemasukan,
    double totalPengeluaran,
    double totalTransfer,
  ) {
    return List.generate(3, (i) {
      final isTouched = i == _touchedPieIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 80.0 : 70.0;
      final widgetSize = isTouched ? 50.0 : 40.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final total = totalPemasukan + totalPengeluaran + totalTransfer;
      final value = i == 0
          ? totalPemasukan
          : (i == 1 ? totalPengeluaran : totalTransfer);
      final percentage = total == 0 ? 0 : (value / total) * 100;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.green,
            value: totalPemasukan,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
              shadows: shadows,
            ),
            badgeWidget: _Badge(
              Icons.arrow_downward,
              size: widgetSize,
              borderColor: Colors.green.shade900,
              backgroundColor: Colors.green,
            ),
            badgePositionPercentageOffset: .98,
          );
        case 1:
          return PieChartSectionData(
            color: Colors.red,
            value: totalPengeluaran,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
              shadows: shadows,
            ),
            badgeWidget: _Badge(
              Icons.arrow_upward,
              size: widgetSize,
              borderColor: Colors.red.shade900,
              backgroundColor: Colors.red,
            ),
            badgePositionPercentageOffset: .98,
          );
        case 2:
          return PieChartSectionData(
            color: Colors.blue,
            value: totalTransfer,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
              shadows: shadows,
            ),
            badgeWidget: _Badge(
              Icons.swap_horiz,
              size: widgetSize,
              borderColor: Colors.blue.shade900,
              backgroundColor: Colors.blue,
            ),
            badgePositionPercentageOffset: .98,
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildLineChart({
    required String title,
    required List<FlSpot> spots,
    required Color color,
    required int minX,
    required int maxX,
    required String filterWaktu,
  }) {
    double maxY = 0;
    for (var spot in spots) {
      if (spot.y > maxY) maxY = spot.y;
    }
    if (maxY == 0) maxY = 1000;
    maxY = maxY * 1.2;

    double intervalY = maxY / 4;
    if (intervalY == 0) intervalY = 1;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: intervalY,
                    verticalInterval: filterWaktu == '1 Hari'
                        ? 4
                        : (filterWaktu == '1 Bulan' ? 5 : 1),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (val, meta) =>
                            _bottomTitleWidgets(val, meta, filterWaktu),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: intervalY,
                        getTitlesWidget: _leftTitleWidgets,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  minX: minX.toDouble(),
                  maxX: maxX.toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.6), color],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.3),
                            color.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, String filterWaktu) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    String text = '';
    if (filterWaktu == '1 Hari') {
      if (value % 4 == 0) text = '${value.toInt()}:00';
    } else if (filterWaktu == '1 Minggu') {
      switch (value.toInt()) {
        case 1:
          text = 'Sen';
          break;
        case 2:
          text = 'Sel';
          break;
        case 3:
          text = 'Rab';
          break;
        case 4:
          text = 'Kam';
          break;
        case 5:
          text = 'Jum';
          break;
        case 6:
          text = 'Sab';
          break;
        case 7:
          text = 'Min';
          break;
      }
    } else if (filterWaktu == '1 Bulan') {
      if (value == 1 || value % 5 == 0) {
        text = value.toInt().toString();
      }
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(text, style: style),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 10);
    String text = '';
    if (value >= 1000000000) {
      text = '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      text = '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(0)}K';
    } else {
      text = value.toStringAsFixed(0);
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8,
      child: Text(text, style: style),
    );
  }
}
