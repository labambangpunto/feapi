import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controllers/transaksi_controller.dart';
import '../models/transaksi_model.dart';
import '../controllers/utang_piutang_controller.dart';
import '../models/utang_piutang_model.dart';
import '../utils/currency_format.dart';
import '../controllers/label_controller.dart';
import '../models/label_model.dart';
import '../controllers/akun_controller.dart';
import '../models/akun_model.dart';

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
  String _filterWaktu = '1 Bulan';
  int _touchedPieIndex = -1;
  String _sortLabel = 'latest';
  String _sortAkun = 'latest';

  @override
  Widget build(BuildContext context) {
    // Pantau langsung transaksi untuk difilter secara lokal
    final transaksiState = ref.watch(transaksiControllerProvider);
    final utangState = ref.watch(utangPiutangControllerProvider);

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
    final namaHari = hariMap[now.weekday];
    final tanggalLengkap = '${now.day} ${bulanMap[now.month]} ${now.year}';
    // 1. DIVISI 1: ARUS KAS TRANSAKSI (Tampilan Utama)
    final divisi1 = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                DropdownMenuItem(value: '1 Minggu', child: Text('Minggu Ini')),
                DropdownMenuItem(value: '1 Bulan', child: Text('Bulan Ini')),
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
            // ... Sisa kode divisi 1 tidak berubah
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
      ],
    );

    // 2. DIVISI 3: TAGIHAN BERJALAN (Tampilan Utama Utang-Piutang)
    final divisi3 = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );

    // 3. DIVISI 2: KELOMPOK SUB-TAMPILAN TRANSAKSI
    final divisi2 = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPieChart(totalPemasukan, totalPengeluaran, totalTransfer),
        _buildCalendarCard(transaksiState.value ?? []),
        _buildTableAkun(
          transaksiState.value ?? [],
          ref.watch(akunControllerProvider).value ?? [],
        ),
        _buildTableAkun(
          transaksiState.value ?? [],
          ref.watch(akunControllerProvider).value ?? [],
        ),
        _buildTableLabel(
          transaksiState.value ?? [],
          ref.watch(labelControllerProvider).value ?? [],
        ),
        _buildLineChart(
          title: 'Tren Pengeluaran',
          spots: pengeluaranSpots,
          color: Colors.red,
          minX: minX,
          maxX: maxX,
          filterWaktu: _filterWaktu,
        ),
        _buildLineChart(
          title: 'Tren Pemasukan',
          spots: pemasukanSpots,
          color: Colors.green,
          minX: minX,
          maxX: maxX,
          filterWaktu: _filterWaktu,
        ),
        _buildLineChart(
          title: 'Tren Transfer Antarakun',
          spots: transferSpots,
          color: Colors.blue,
          minX: minX,
          maxX: maxX,
          filterWaktu: _filterWaktu,
        ),
      ],
    );

    // 4. DIVISI 4: KELOMPOK SUB-TAMPILAN UTANG-PIUTANG (Coming Soon)
    final divisi4 = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 64, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Sub-tampilan Utang-Piutang\n(Coming Soon)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 5. PENYUSUNAN TATA LETAK RESPONSIF
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76, // Mengatur tinggi agar muat untuk dua baris teks
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              namaHari,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              tanggalLengkap,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop =
                constraints.maxWidth >
                800; // Breakpoint batas dua kolom (desktop)

            if (isDesktop) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kolom Kiri: Hal Transaksi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          divisi1,
                          const SizedBox(height: 32),
                          divisi2,
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Kolom Kanan: Hal Utang-Piutang
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          divisi3,
                          const SizedBox(height: 32),
                          divisi4,
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Tampilan Mobile (Satu Kolom)
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  divisi1,
                  const SizedBox(height: 32),
                  divisi3,
                  const SizedBox(height: 32),
                  divisi2,
                  const SizedBox(height: 32),
                  divisi4,
                ],
              );
            }
          },
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

  Widget _buildCalendarCard(List<TransaksiModel> transaksiList) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    // Hitung rekap harian untuk bulan ini
    final Map<int, _DailyStat> dailyStats = {};
    for (var t in transaksiList) {
      if (t.waktu.year == year && t.waktu.month == month) {
        final day = t.waktu.day;
        final nominal = (t.nominal * t.kuantitas) + (t.biayaTambahan ?? 0);

        dailyStats.putIfAbsent(day, () => _DailyStat());
        if (t.tipe == TipeTransaksi.pemasukan) {
          dailyStats[day]!.pemasukan += nominal;
        } else if (t.tipe == TipeTransaksi.pengeluaran) {
          dailyStats[day]!.pengeluaran += nominal;
        } else if (t.tipe == TipeTransaksi.transfer) {
          dailyStats[day]!.transfer += nominal;
        }
      }
    }

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Dart: Senin=1, Minggu=7 -> Ubah agar Minggu=0
    final firstWeekday = firstDayOfMonth.weekday == 7
        ? 0
        : firstDayOfMonth.weekday;

    final List<String> hariStr = [
      'Min',
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
    ];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kalender Transaksi Bulan Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: hariStr
                  .map(
                    (h) => Expanded(
                      child: Text(
                        h,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: firstWeekday + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstWeekday) return const SizedBox();

                final day = index - firstWeekday + 1;
                final stat = dailyStats[day];
                final hasData =
                    stat != null &&
                    (stat.pemasukan > 0 ||
                        stat.pengeluaran > 0 ||
                        stat.transfer > 0);

                // Siapkan teks Tooltip
                String tooltipText = 'Tanggal $day\n';
                if (hasData) {
                  tooltipText += 'Pemasukan: ${stat.pemasukan.toIdr()}\n';
                  tooltipText += 'Pengeluaran: ${stat.pengeluaran.toIdr()}\n';
                  tooltipText += 'Transfer: ${stat.transfer.toIdr()}';
                } else {
                  tooltipText += 'Tidak ada transaksi';
                }

                return Tooltip(
                  message: tooltipText,
                  triggerMode: TooltipTriggerMode
                      .tap, // Akan muncul saat diklik di Mobile
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  showDuration: const Duration(seconds: 3),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: day == now.day
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          day.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: day == now.day
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: day == now.day ? Colors.blue : null,
                          ),
                        ),
                        if (hasData) ...[
                          const Spacer(),
                          if (stat.pemasukan > 0)
                            _buildMiniIndicator(Colors.green, stat.pemasukan),
                          if (stat.pengeluaran > 0)
                            _buildMiniIndicator(Colors.red, stat.pengeluaran),
                          if (stat.transfer > 0)
                            _buildMiniIndicator(Colors.blue, stat.transfer),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniIndicator(Color color, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _formatSingkat(value),
          style: TextStyle(
            fontSize: 8,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatSingkat(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
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

  Widget _buildTableAkun(
    List<TransaksiModel> transaksiList,
    List<AkunModel> akunList,
  ) {
    final now = DateTime.now();

    final filteredTransaksi = transaksiList.where((t) {
      if (_filterWaktu == '1 Hari') {
        return t.waktu.year == now.year &&
            t.waktu.month == now.month &&
            t.waktu.day == now.day;
      } else if (_filterWaktu == '1 Minggu') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final sDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final tDate = DateTime(t.waktu.year, t.waktu.month, t.waktu.day);
        return tDate.isAfter(sDate.subtract(const Duration(days: 1))) &&
            tDate.isBefore(
              DateTime(
                now.year,
                now.month,
                now.day,
              ).add(const Duration(days: 1)),
            );
      } else if (_filterWaktu == '1 Bulan') {
        return t.waktu.year == now.year && t.waktu.month == now.month;
      }
      return false;
    }).toList();

    final Map<String, _AkunStat> statsMap = {};

    String getNamaAkun(String id) {
      try {
        return akunList.firstWhere((a) => a.id == id).nama;
      } catch (_) {
        return 'Akun Terhapus';
      }
    }

    void prosesStatAkun(
      String? akunId,
      double nominal,
      TipeTransaksi tipe,
      DateTime waktu, {
      bool isTransferSumber = false,
    }) {
      if (akunId == null || akunId.isEmpty) return;

      final stat = statsMap.putIfAbsent(
        akunId,
        () => _AkunStat(getNamaAkun(akunId)),
      );

      if (tipe == TipeTransaksi.pengeluaran) {
        stat.pengeluaran += nominal;
      } else if (tipe == TipeTransaksi.pemasukan) {
        stat.pemasukan += nominal;
      } else if (tipe == TipeTransaksi.transfer) {
        if (isTransferSumber) {
          stat.transferSumber += nominal;
        } else {
          stat.transferTujuan += nominal;
        }
      }

      if (stat.latestWaktu == null || waktu.isAfter(stat.latestWaktu!)) {
        stat.latestWaktu = waktu;
      }
    }

    for (var t in filteredTransaksi) {
      final nominal = (t.nominal * t.kuantitas) + (t.biayaTambahan ?? 0);

      if (t.tipe == TipeTransaksi.pengeluaran) {
        prosesStatAkun(t.akunSumberId, nominal, t.tipe, t.waktu);
      } else if (t.tipe == TipeTransaksi.pemasukan) {
        prosesStatAkun(t.akunTujuanId, nominal, t.tipe, t.waktu);
      } else if (t.tipe == TipeTransaksi.transfer) {
        prosesStatAkun(
          t.akunSumberId,
          nominal,
          t.tipe,
          t.waktu,
          isTransferSumber: true,
        );
        prosesStatAkun(
          t.akunTujuanId,
          nominal,
          t.tipe,
          t.waktu,
          isTransferSumber: false,
        );
      }
    }

    List<_AkunStat> statList = statsMap.values.toList();

    switch (_sortAkun) {
      case 'A-Z':
        statList.sort(
          (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
        );
        break;
      case 'Z-A':
        statList.sort(
          (a, b) => b.nama.toLowerCase().compareTo(a.nama.toLowerCase()),
        );
        break;
      case 'latest':
        statList.sort(
          (a, b) => (b.latestWaktu ?? DateTime(2000)).compareTo(
            a.latestWaktu ?? DateTime(2000),
          ),
        );
        break;
      case 'largest':
        statList.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'smallest':
        statList.sort((a, b) => a.total.compareTo(b.total));
        break;
    }

    final displayList = statList.take(5).toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total per Akun',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _sortAkun,
                  underline: const SizedBox(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'largest', child: Text('Terbesar')),
                    DropdownMenuItem(
                      value: 'smallest',
                      child: Text('Terkecil'),
                    ),
                    DropdownMenuItem(value: 'latest', child: Text('Terbaru')),
                    DropdownMenuItem(value: 'A-Z', child: Text('A - Z')),
                    DropdownMenuItem(value: 'Z-A', child: Text('Z - A')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortAkun = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowHeight: 40,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 44,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Akun',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Pengeluaran',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Pemasukan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Transfer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: displayList.isEmpty
                      ? [
                          const DataRow(
                            cells: [
                              DataCell(Text('Belum ada data')),
                              DataCell(Text('-')),
                              DataCell(Text('-')),
                              DataCell(Text('-')),
                            ],
                          ),
                        ]
                      : displayList.map((item) {
                          String transferText = '-';
                          if (item.transferSumber > 0 &&
                              item.transferTujuan > 0) {
                            transferText =
                                '${item.transferSumber.toIdr()} (sumber)\n${item.transferTujuan.toIdr()} (tujuan)';
                          } else if (item.transferSumber > 0) {
                            transferText =
                                '${item.transferSumber.toIdr()} (sumber)';
                          } else if (item.transferTujuan > 0) {
                            transferText =
                                '${item.transferTujuan.toIdr()} (tujuan)';
                          } else {
                            transferText = '0';
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  item.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.pengeluaran.toIdr(),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.pemasukan.toIdr(),
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                              DataCell(
                                Text(
                                  transferText,
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableLabel(
    List<TransaksiModel> transaksiList,
    List<LabelModel> labelList,
  ) {
    final now = DateTime.now();

    final filteredTransaksi = transaksiList.where((t) {
      if (_filterWaktu == '1 Hari') {
        return t.waktu.year == now.year &&
            t.waktu.month == now.month &&
            t.waktu.day == now.day;
      } else if (_filterWaktu == '1 Minggu') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final sDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final tDate = DateTime(t.waktu.year, t.waktu.month, t.waktu.day);
        return tDate.isAfter(sDate.subtract(const Duration(days: 1))) &&
            tDate.isBefore(
              DateTime(
                now.year,
                now.month,
                now.day,
              ).add(const Duration(days: 1)),
            );
      } else if (_filterWaktu == '1 Bulan') {
        return t.waktu.year == now.year && t.waktu.month == now.month;
      }
      return false;
    }).toList();

    final Map<String, _LabelStat> statsMap = {};

    String getNamaLabel(String id) {
      try {
        return labelList.firstWhere((l) => l.id == id).nama;
      } catch (_) {
        return 'Label Terhapus';
      }
    }

    for (var t in filteredTransaksi) {
      final nominal = (t.nominal * t.kuantitas) + (t.biayaTambahan ?? 0);
      List<String> ids = (t.labelId != null && t.labelId!.isNotEmpty)
          ? t.labelId!.split(',')
          : ['tanpa_label'];

      for (var id in ids) {
        final nama = id == 'tanpa_label' ? 'Tanpa Label' : getNamaLabel(id);
        final stat = statsMap.putIfAbsent(id, () => _LabelStat(nama));

        if (t.tipe == TipeTransaksi.pengeluaran) {
          stat.pengeluaran += nominal;
        } else if (t.tipe == TipeTransaksi.pemasukan) {
          stat.pemasukan += nominal;
        } else if (t.tipe == TipeTransaksi.transfer) {
          stat.transfer += nominal;
        }

        if (stat.latestWaktu == null || t.waktu.isAfter(stat.latestWaktu!)) {
          stat.latestWaktu = t.waktu;
        }
      }
    }

    List<_LabelStat> statList = statsMap.values.toList();

    switch (_sortLabel) {
      case 'A-Z':
        statList.sort(
          (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
        );
        break;
      case 'Z-A':
        statList.sort(
          (a, b) => b.nama.toLowerCase().compareTo(a.nama.toLowerCase()),
        );
        break;
      case 'latest':
        statList.sort(
          (a, b) => (b.latestWaktu ?? DateTime(2000)).compareTo(
            a.latestWaktu ?? DateTime(2000),
          ),
        );
        break;
      case 'largest':
        statList.sort((a, b) => b.total.compareTo(a.total));
        break;
      case 'smallest':
        statList.sort((a, b) => a.total.compareTo(b.total));
        break;
    }

    final displayList = statList.take(5).toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total per Label',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _sortLabel,
                  underline: const SizedBox(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'largest', child: Text('Terbesar')),
                    DropdownMenuItem(
                      value: 'smallest',
                      child: Text('Terkecil'),
                    ),
                    DropdownMenuItem(value: 'latest', child: Text('Terbaru')),
                    DropdownMenuItem(value: 'A-Z', child: Text('A - Z')),
                    DropdownMenuItem(value: 'Z-A', child: Text('Z - A')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortLabel = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingRowHeight: 40,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 44,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Label',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Keluar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Masuk',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Transfer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: displayList.isEmpty
                      ? [
                          const DataRow(
                            cells: [
                              DataCell(Text('No data')),
                              DataCell(Text('-')),
                              DataCell(Text('-')),
                              DataCell(Text('-')),
                            ],
                          ),
                        ]
                      : displayList.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  item.nama,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.pengeluaran.toIdr(),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.pemasukan.toIdr(),
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                              DataCell(
                                Text(
                                  item.transfer.toIdr(),
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} // AKHIR DARI CLASS _HomeScreenState

class _AkunStat {
  final String nama;
  double pengeluaran = 0;
  double pemasukan = 0;
  double transferSumber = 0;
  double transferTujuan = 0;
  DateTime? latestWaktu;

  _AkunStat(this.nama);
  double get total => pengeluaran + pemasukan + transferSumber + transferTujuan;
}

class _LabelStat {
  final String nama;
  double pengeluaran = 0;
  double pemasukan = 0;
  double transfer = 0;
  DateTime? latestWaktu;

  _LabelStat(this.nama);
  double get total => pengeluaran + pemasukan + transfer;
}

class _DailyStat {
  double pengeluaran = 0;
  double pemasukan = 0;
  double transfer = 0;
}
