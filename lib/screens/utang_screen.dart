import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/utang_piutang_controller.dart';
import '../models/utang_piutang_model.dart';
import '../controllers/akun_controller.dart';
import '../models/akun_model.dart';
import '../utils/currency_format.dart';
import '../utils/currency_formatter.dart';
import 'form_utang_piutang.dart';

class UtangScreen extends ConsumerStatefulWidget {
  const UtangScreen({super.key});

  @override
  ConsumerState<UtangScreen> createState() => _UtangScreenState();
}

class _UtangScreenState extends ConsumerState<UtangScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _filterTanggal;

  bool _isFilterActive = false;
  String _filterKataKunci = '';
  String? _filterAkunId;
  bool? _filterStatusLunas;
  double? _filterMinNominal;
  double? _filterMaxNominal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(utangPiutangControllerProvider);
    final akunList = ref.watch(akunControllerProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utang & Piutang'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Utang'),
            Tab(text: 'Piutang'),
          ],
        ),
        actions: [
          if (_isFilterActive)
            Tooltip(
              message: 'Hapus Filter',
              child: IconButton(
                icon: const Icon(Icons.filter_alt_off),
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
              ),
            )
          else
            Tooltip(
              message: 'Cari / Filter',
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _tampilFormFilter(akunList),
              ),
            ),
          Tooltip(
            message: 'Filter Tanggal',
            child: IconButton(
              icon: const Icon(Icons.calendar_month),
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
          ),
          if (_filterTanggal != null)
            Tooltip(
              message: 'Hapus Filter Tanggal',
              child: IconButton(
                icon: const Icon(Icons.event_busy),
                onPressed: () => setState(() => _filterTanggal = null),
              ),
            ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (listData) {
          var filteredList = listData;

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

          if (_isFilterActive) {
            if (_filterStatusLunas != null) {
              filteredList = filteredList
                  .where((e) => e.isLunas == _filterStatusLunas)
                  .toList();
            }
            if (_filterKataKunci.isNotEmpty) {
              final query = _filterKataKunci.toLowerCase();
              filteredList = filteredList
                  .where(
                    (e) =>
                        e.pihakTerkait.toLowerCase().contains(query) ||
                        e.catatan.toLowerCase().contains(query),
                  )
                  .toList();
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
            controller: _tabController,
            children: [
              _buildList(listUtang, context, ref, akunList),
              _buildList(listPiutang, context, ref, akunList),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.arrow_downward,
                        color: Colors.red,
                      ),
                      title: const Text('Tambah Utang'),
                      onTap: () {
                        Navigator.pop(dialogContext);
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
                        Navigator.pop(dialogContext);
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
          );
        },
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _tampilFormPelunasan(context, ref, item),
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
                      decoration: item.isLunas
                          ? TextDecoration.lineThrough
                          : null,
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
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Container(
                          decoration: BoxDecoration(
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
                        icon: const Icon(Icons.more_vert),
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
                            showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Konfirmasi Hapus'),
                                content: Text(
                                  'Apakah Anda yakin ingin menghapus data ${isUtang ? "utang" : "piutang"} ini?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Batal'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      ref
                                          .read(
                                            utangPiutangControllerProvider
                                                .notifier,
                                          )
                                          .hapusUtangPiutang(item.id);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
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
                    ],
                  ),
                ),
              ),
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

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final akunState = ref.watch(akunControllerProvider);
            return AlertDialog(
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
                    SizedBox(
                      width: double.infinity,

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

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!item.isLunas) ...[
                      const SizedBox(height: 30),
                      const Text(
                        'Form Pelunasan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 11),
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
                      const SizedBox(height: 1),
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(item.isLunas ? 'Tutup' : 'Batal'),
                ),
                if (!item.isLunas)
                  FilledButton(
                    onPressed: () {
                      if (selectedAkunId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pilih akun pelunasan!'),
                          ),
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

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextState, setStateDialog) {
            return AlertDialog(
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
                            decoration: const InputDecoration(
                              labelText: 'Nominal Min (Rp)',
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
                            decoration: const InputDecoration(
                              labelText: 'Nominal Max (Rp)',
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
                    Navigator.pop(dialogContext);
                    setState(() {
                      _isFilterActive = false;
                      _filterKataKunci = '';
                      _filterAkunId = null;
                      _filterStatusLunas = null;
                      _filterMinNominal = null;
                      _filterMaxNominal = null;
                    });
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    setState(() {
                      _filterKataKunci = tempKataKunci.trim();
                      _filterAkunId = tempAkunId;
                      _filterStatusLunas = tempStatusLunas;
                      _filterMinNominal = minCtrl.text.isNotEmpty
                          ? double.parse(minCtrl.text.replaceAll('.', ''))
                          : null;
                      _filterMaxNominal = maxCtrl.text.isNotEmpty
                          ? double.parse(maxCtrl.text.replaceAll('.', ''))
                          : null;
                      _isFilterActive =
                          _filterKataKunci.isNotEmpty ||
                          _filterAkunId != null ||
                          _filterStatusLunas != null ||
                          _filterMinNominal != null ||
                          _filterMaxNominal != null;
                    });
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
