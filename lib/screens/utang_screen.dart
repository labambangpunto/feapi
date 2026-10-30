import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/utang_piutang_controller.dart';
import '../models/utang_piutang_model.dart';
import '../controllers/akun_controller.dart';
import '../models/akun_model.dart';
import '../utils/currency_format.dart';
import '../utils/currency_formatter.dart';
import 'form_utang_piutang.dart';

final utangFilterTanggalProvider = StateProvider<DateTime?>((ref) => null);
final utangIsFilterActiveProvider = StateProvider<bool>((ref) => false);
final utangFilterKataKunciProvider = StateProvider<String>((ref) => '');
final utangFilterAkunIdProvider = StateProvider<String?>((ref) => null);
final utangFilterStatusLunasProvider = StateProvider<bool?>((ref) => null);
final utangFilterMinNominalProvider = StateProvider<double?>((ref) => null);
final utangFilterMaxNominalProvider = StateProvider<double?>((ref) => null);

class UtangScreen extends ConsumerStatefulWidget {
  const UtangScreen({super.key});

  @override
  ConsumerState<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends ConsumerState<UtangScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(utangPiutangControllerProvider);
    final akunList = ref.watch(akunControllerProvider).value ?? [];

    // Pantau state filter utang/piutang
    final filterTanggal = ref.watch(utangFilterTanggalProvider);
    final isFilterActive = ref.watch(utangIsFilterActiveProvider);
    final filterKataKunci = ref.watch(utangFilterKataKunciProvider);
    final filterAkunId = ref.watch(utangFilterAkunIdProvider);
    final filterStatusLunas = ref.watch(utangFilterStatusLunasProvider);
    final filterMinNominal = ref.watch(utangFilterMinNominalProvider);
    final filterMaxNominal = ref.watch(utangFilterMaxNominalProvider);

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

    String topLabelInfo = 'Utang & Piutang';
    if (filterTanggal != null) {
      topLabelInfo =
          'Utang/Piutang pada ${filterTanggal.day.toString().padLeft(2, '0')} ${bulanMap[filterTanggal.month]} ${filterTanggal.year}';
    } else if (isFilterActive) {
      topLabelInfo = 'Hasil Pencarian Utang & Piutang';
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              topLabelInfo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (isFilterActive || filterTanggal != null)
              Text(
                'Filter nyala',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(23),
            ),
            icon: const Icon(Icons.menu_rounded),
            onSelected: (value) async {
              switch (value) {
                case 'filter':
                  _tampilFormFilter(akunList);
                  break;
                case 'hapus_filter':
                  ref.read(utangIsFilterActiveProvider.notifier).state = false;
                  ref.read(utangFilterKataKunciProvider.notifier).state = '';
                  ref.read(utangFilterAkunIdProvider.notifier).state = null;
                  ref.read(utangFilterStatusLunasProvider.notifier).state =
                      null;
                  ref.read(utangFilterMinNominalProvider.notifier).state = null;
                  ref.read(utangFilterMaxNominalProvider.notifier).state = null;
                  break;
                case 'tanggal':
                  final date = await showDatePicker(
                    context: context,
                    initialDate: filterTanggal ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    ref.read(utangFilterTanggalProvider.notifier).state = date;
                  }
                  break;
                case 'hapus_tanggal':
                  ref.read(utangFilterTanggalProvider.notifier).state = null;
                  break;
              }
            },
            itemBuilder: (context) => [
              if (isFilterActive)
                const PopupMenuItem(
                  value: 'hapus_filter',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_off_rounded, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Hapus Filter Kriteria'),
                    ],
                  ),
                )
              else
                const PopupMenuItem(
                  value: 'filter',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_rounded, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Filter Kriteria'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'tanggal',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Filter Tanggal Spesifik'),
                  ],
                ),
              ),
              if (filterTanggal != null)
                const PopupMenuItem(
                  value: 'hapus_tanggal',
                  child: Row(
                    children: [
                      Icon(Icons.event_busy, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Hapus Filter Tanggal'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (listData) {
          var filteredList = listData;

          // 1. Terapkan Filter Tanggal
          if (filterTanggal != null) {
            filteredList = filteredList
                .where(
                  (e) =>
                      e.waktu.year == filterTanggal.year &&
                      e.waktu.month == filterTanggal.month &&
                      e.waktu.day == filterTanggal.day,
                )
                .toList();
          }

          // 2. Terapkan Filter Kriteria
          if (isFilterActive) {
            if (filterStatusLunas != null) {
              filteredList = filteredList
                  .where((e) => e.isLunas == filterStatusLunas)
                  .toList();
            }
            if (filterKataKunci.isNotEmpty) {
              final query = filterKataKunci.toLowerCase();
              filteredList = filteredList
                  .where(
                    (e) =>
                        e.pihakTerkait.toLowerCase().contains(query) ||
                        e.catatan.toLowerCase().contains(query),
                  )
                  .toList();
            }
            if (filterAkunId != null) {
              filteredList = filteredList
                  .where((e) => e.akunId == filterAkunId)
                  .toList();
            }
            if (filterMinNominal != null) {
              filteredList = filteredList
                  .where((e) => e.nominal >= filterMinNominal)
                  .toList();
            }
            if (filterMaxNominal != null) {
              filteredList = filteredList
                  .where((e) => e.nominal <= filterMaxNominal)
                  .toList();
            }
          }

          // 3. Urutkan berdasarkan waktu (terbaru di atas)
          filteredList.sort((a, b) => b.waktu.compareTo(a.waktu));

          if (filteredList.isEmpty) {
            return const Center(child: Text('Tidak ada data yang cocok'));
          }

          String formatHeadingTanggal(DateTime dt) {
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
            return '${hariMap[dt.weekday]}, ${dt.day.toString().padLeft(2, '0')} ${bulanMap[dt.month]} ${dt.year}';
          }

          // 4. Bangun Layout Grid
          return LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final isDesktop = w > 1000;
              final isTablet = w > 600 && w <= 1000;
              final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

              int countUtang = 0;
              int countPiutang = 0;

              for (var item in filteredList) {
                if (item.tipe == TipeUtangPiutang.utang) {
                  countUtang++;
                } else if (item.tipe == TipeUtangPiutang.piutang) {
                  countPiutang++;
                }
              }

              // Kelompokkan data per tanggal
              final Map<String, List<UtangPiutangModel>> groupedData = {};
              for (var item in filteredList) {
                final dateKey =
                    '${item.waktu.year}-${item.waktu.month}-${item.waktu.day}';
                groupedData.putIfAbsent(dateKey, () => []).add(item);
              }

              return CustomScrollView(
                slivers: [
                  for (final entry in groupedData.entries) ...[
                    // Header Tanggal (Full-Width)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          formatHeadingTanggal(entry.value.first.waktu),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ),
                    ),
                    // Grid Data Utang & Piutang

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisExtent:
                              180, // Ditinggikan untuk memuat detail lengkap
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = entry.value[index];
                          final isUtang = item.tipe == TipeUtangPiutang.utang;
                          final colorTipe = isUtang
                              ? Colors.orange
                              : Colors.blue;

                          String namaAkunAwal = '-';
                          if (item.akunId != null) {
                            try {
                              namaAkunAwal = akunList
                                  .firstWhere((a) => a.id == item.akunId)
                                  .nama;
                            } catch (_) {
                              namaAkunAwal = 'Akun terhapus';
                            }
                          }

                          final tglBuat =
                              '${item.waktu.day.toString().padLeft(2, '0')} ${bulanMap[item.waktu.month]} ${item.waktu.year}';
                          final tglJatuhTempo = item.tenggatWaktu;
                          final formatJatuhTempo =
                              '${tglJatuhTempo.day.toString().padLeft(2, '0')} ${bulanMap[tglJatuhTempo.month]} ${tglJatuhTempo.year}';

                          return Card(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: item.isLunas ? Colors.grey : colorTipe,
                                width: 1.5,
                              ),
                            ),
                            color: item.isLunas ? Colors.grey.shade100 : null,
                            child: InkWell(
                              // Hilangkan aksi onTap pelunasan dari card
                              onTap: null,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.nominal.toIdr(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: item.isLunas
                                                  ? Colors.grey
                                                  : colorTipe,
                                              decoration: item.isLunas
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (item.isLunas)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                            SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: PopupMenuButton<String>(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(23),
                                                ),
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                  size: 20,
                                                ),
                                                onSelected: (value) {
                                                  if (value == 'pelunasan') {
                                                    _tampilFormPelunasan(
                                                      context,
                                                      ref,
                                                      item,
                                                    );
                                                  } else if (value == 'edit') {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            FormUtangPiutangScreen(
                                                              tipe: item.tipe,
                                                              dataEdit: item,
                                                            ),
                                                      ),
                                                    );
                                                  } else if (value == 'hapus') {
                                                    showDialog<void>(
                                                      context: context,
                                                      builder: (_) => AlertDialog(
                                                        title: const Text(
                                                          'Konfirmasi Hapus',
                                                        ),
                                                        content: Text(
                                                          'Apakah Anda yakin ingin menghapus data ${isUtang ? "utang" : "piutang"} ini?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                ),
                                                            child: const Text(
                                                              'Batal',
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            onPressed: () {
                                                              ref
                                                                  .read(
                                                                    utangPiutangControllerProvider
                                                                        .notifier,
                                                                  )
                                                                  .hapusUtangPiutang(
                                                                    item.id,
                                                                  );
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                            },
                                                            child: const Text(
                                                              'Hapus',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  if (!item.isLunas)
                                                    const PopupMenuItem(
                                                      value: 'pelunasan',
                                                      child: Text('Pelunasan'),
                                                    ),
                                                  if (!item.isLunas)
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
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isUtang
                                          ? 'Utang ke: ${item.pihakTerkait}'
                                          : 'Piutang ke: ${item.pihakTerkait}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Akun: $namaAkunAwal',
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.catatan.isNotEmpty)
                                      Text(
                                        'Cat: ${item.catatan}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const Spacer(),
                                    const Divider(height: 12),
                                    Text(
                                      'Dibuat: $tglBuat',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Tempo: $formatJatuhTempo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: item.isLunas
                                            ? Colors.grey
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: entry.value.length),
                      ),
                    ),
                  ],
                  if (filteredList.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 88),
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
                                  'Ringkasan Jumlah Catatan',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        const Icon(
                                          Icons.arrow_downward,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$countUtang Utang',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(
                                          Icons.arrow_upward,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$countPiutang Piutang',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: PopupMenuButton<TipeUtangPiutang>(
        offset: const Offset(0, -120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
        onSelected: (tipe) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormUtangPiutangScreen(tipe: tipe),
            ),
          );
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: TipeUtangPiutang.utang,
            child: Row(
              children: [
                Icon(Icons.arrow_downward, color: Colors.orange),
                SizedBox(width: 16),
                Text('Tambah Utang'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: TipeUtangPiutang.piutang,
            child: Row(
              children: [
                Icon(Icons.arrow_upward, color: Colors.blue),
                SizedBox(width: 16),
                Text('Tambah Piutang'),
              ],
            ),
          ),
        ],
        child: Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              Icons.add_rounded,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
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

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final akunState = ref.watch(akunControllerProvider);
            return AlertDialog(
              title: Text(isUtang ? 'Pelunasan Utang' : 'Pelunasan Piutang'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${item.nominal.toIdr()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            setStateDialog(() => selectedAkunId = val),
                      ),
                      orElse: () => const CircularProgressIndicator(),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Tanggal Pelunasan',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${selectedDate.day.toString().padLeft(2, '0')} ${bulanMap[selectedDate.month]} ${selectedDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setStateDialog(() => selectedDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedAkunId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pilih akun pelunasan!')),
                      );
                      return;
                    }

                    final updatedItem = UtangPiutangModel(
                      id: item.id,
                      tipe: item.tipe,
                      nominal: item.nominal,
                      pihakTerkait: item.pihakTerkait,
                      akunId: selectedAkunId,
                      waktu: item.waktu,
                      tenggatWaktu: item.tenggatWaktu,
                      catatan: item.catatan,
                      isLunas: true,
                    );
                    ref
                        .read(utangPiutangControllerProvider.notifier)
                        .updateUtangPiutang(updatedItem);
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
    String tempKataKunci = ref.read(utangFilterKataKunciProvider);
    String? tempAkunId = ref.read(utangFilterAkunIdProvider);
    bool? tempStatusLunas = ref.read(utangFilterStatusLunasProvider);

    final minVal = ref.read(utangFilterMinNominalProvider);
    final maxVal = ref.read(utangFilterMaxNominalProvider);

    final kataCtrl = TextEditingController(text: tempKataKunci);
    final minCtrl = TextEditingController(
      text: minVal != null ? minVal.toRibuan() : '',
    );
    final maxCtrl = TextEditingController(
      text: maxVal != null ? maxVal.toRibuan() : '',
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextState, setStateDialog) {
            return AlertDialog(
              title: const Text('Filter Utang Piutang'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<bool?>(
                      initialValue: tempStatusLunas,
                      decoration: const InputDecoration(
                        labelText: 'Status Pelunasan',
                        border: OutlineInputBorder(),
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
                          setStateDialog(() => tempStatusLunas = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: kataCtrl,
                      maxLength: 64,
                      decoration: const InputDecoration(
                        labelText: 'Pihak Terkait atau Catatan',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => tempKataKunci = val,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: tempAkunId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Akun Terkait',
                        border: OutlineInputBorder(),
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
                      onChanged: (val) =>
                          setStateDialog(() => tempAkunId = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyFormatter()],
                            maxLength: 11,
                            decoration: const InputDecoration(
                              labelText: 'Min (Rp)',
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyFormatter()],
                            maxLength: 11,
                            decoration: const InputDecoration(
                              labelText: 'Max (Rp)',
                              counterText: '',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(utangIsFilterActiveProvider.notifier).state =
                        false;
                    ref.read(utangFilterKataKunciProvider.notifier).state = '';
                    ref.read(utangFilterAkunIdProvider.notifier).state = null;
                    ref.read(utangFilterStatusLunasProvider.notifier).state =
                        null;
                    ref.read(utangFilterMinNominalProvider.notifier).state =
                        null;
                    ref.read(utangFilterMaxNominalProvider.notifier).state =
                        null;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (minCtrl.text.isNotEmpty && maxCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wajib mengisi Max (Rp) jika Min (Rp) diisi',
                          ),
                        ),
                      );
                      return;
                    }
                    if (minCtrl.text.isEmpty && maxCtrl.text.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Wajib mengisi Min (Rp) jika Max (Rp) diisi',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    final parsedMin = minCtrl.text.isNotEmpty
                        ? double.parse(minCtrl.text.replaceAll('.', ''))
                        : null;
                    final parsedMax = maxCtrl.text.isNotEmpty
                        ? double.parse(maxCtrl.text.replaceAll('.', ''))
                        : null;

                    ref.read(utangFilterKataKunciProvider.notifier).state =
                        tempKataKunci.trim();
                    ref.read(utangFilterAkunIdProvider.notifier).state =
                        tempAkunId;
                    ref.read(utangFilterStatusLunasProvider.notifier).state =
                        tempStatusLunas;
                    ref.read(utangFilterMinNominalProvider.notifier).state =
                        parsedMin;
                    ref.read(utangFilterMaxNominalProvider.notifier).state =
                        parsedMax;

                    ref.read(utangIsFilterActiveProvider.notifier).state =
                        tempKataKunci.trim().isNotEmpty ||
                        tempAkunId != null ||
                        tempStatusLunas != null ||
                        parsedMin != null ||
                        parsedMax != null;
                  },
                  child: const Text('Cari'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
