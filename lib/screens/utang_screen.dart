import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
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

class _UtangScreenState extends ConsumerState<UtangScreen> {
  DateTime? _filterTanggal;
  int _tabIndex = 0;

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

    return Scaffold(
      appBar: M3EAppBar.top(
        titleText: 'Utang & Piutang',
        actions: [
          if (_isFilterActive)
            M3ETooltip(
              message: 'Hapus Filter',
              child: M3EIconButton(
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
            M3ETooltip(
              message: 'Cari / Filter',
              child: M3EIconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _tampilFormFilter(akunList),
              ),
            ),
          M3ETooltip(
            message: 'Filter Tanggal',
            child: M3EIconButton(
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
            M3ETooltip(
              message: 'Hapus Filter Tanggal',
              child: M3EIconButton(
                icon: const Icon(Icons.event_busy),
                onPressed: () => setState(() => _filterTanggal = null),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          M3ETabs(
            selectedIndex: _tabIndex,
            onTabSelected: (i) => setState(() => _tabIndex = i),
            tabs: const [
              M3ETab(label: 'Utang'),
              M3ETab(label: 'Piutang'),
            ],
          ),
          Expanded(
            child: state.when(
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

                if (_tabIndex == 0) {
                  return _buildList(listUtang, context, ref, akunList);
                } else {
                  return _buildList(listPiutang, context, ref, akunList);
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: M3EFabMenu(
        expandIcon: const Icon(Icons.add),
        collapseIcon: const Icon(Icons.close),
        items: [
          M3EFabMenuItem(
            icon: const Icon(Icons.arrow_downward, color: Colors.red),
            label: 'Tambah Utang',
            onPressed: () {
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
          M3EFabMenuItem(
            icon: const Icon(Icons.arrow_upward, color: Colors.green),
            label: 'Tambah Piutang',
            onPressed: () {
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
          child: M3ECard(
            variant: M3ECardVariant.elevated,
            onPressed: () => _tampilFormPelunasan(context, ref, item),
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
                    M3EMenu(
                      anchorBuilder: (context, open) => M3EIconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: open,
                      ),
                      children: [
                        M3EMenuGroup.entries(
                          entries: [
                            if (!item.isLunas)
                              M3EMenuEntry(
                                label: 'Edit',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FormUtangPiutangScreen(
                                        tipe: item.tipe,
                                        dataEdit: item,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            M3EMenuEntry(
                              label: 'Hapus',
                              onPressed: () {
                                M3EDialog.show<void>(
                                  context,
                                  dialog: M3EDialog(
                                    title: 'Konfirmasi Hapus',
                                    content: Text(
                                      'Apakah Anda yakin ingin menghapus data ${isUtang ? "utang" : "piutang"} ini?',
                                    ),
                                    actions: [
                                      M3EButton.text(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Batal'),
                                      ),
                                      M3EButton.filled(
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
                              },
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

    M3EDialog.show<void>(
      context,
      dialog: M3EDialog(
        title: item.isLunas
            ? (isUtang ? 'Detail Utang' : 'Detail Piutang')
            : (isUtang ? 'Pelunasan Utang' : 'Pelunasan Piutang'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            final akunState = ref.watch(akunControllerProvider);
            return Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
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
                              setStateDialog(() => selectedAkunId = val),
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
                          if (date != null) {
                            setStateDialog(() => selectedDate = date);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          M3EButton.text(
            onPressed: () => Navigator.pop(context),
            child: Text(item.isLunas ? 'Tutup' : 'Batal'),
          ),
          if (!item.isLunas)
            M3EButton.filled(
              onPressed: () {
                if (selectedAkunId == null) {
                  M3ESnackbar.show(
                    context,
                    message: 'Pilih akun pelunasan terlebih dahulu!',
                  );
                  return;
                }

                // Hanya memperbarui status utang/piutang menjadi lunas, tanpa menyisipkan transaksi.
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
      ),
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
              child: Material(
                color: Colors.transparent,
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
                        onChanged: (val) =>
                            setStateSheet(() => tempAkunId = val),
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
                            child: M3EButton.outlined(
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
                            child: M3EButton.filled(
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
              ),
            );
          },
        );
      },
    );
  }
}
