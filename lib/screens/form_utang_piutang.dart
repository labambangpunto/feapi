import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/akun_controller.dart';
import '../controllers/utang_piutang_controller.dart';
import '../models/utang_piutang_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/currency_format.dart';
import 'kelola_akun_screen.dart';

class FormUtangPiutangScreen extends ConsumerStatefulWidget {
  final TipeUtangPiutang tipe;
  final UtangPiutangModel? dataEdit;

  const FormUtangPiutangScreen({super.key, required this.tipe, this.dataEdit});

  @override
  ConsumerState<FormUtangPiutangScreen> createState() =>
      _FormUtangPiutangScreenState();
}

class _FormUtangPiutangScreenState
    extends ConsumerState<FormUtangPiutangScreen> {
  final _nominalController = TextEditingController();
  final _pihakController = TextEditingController();
  final _catatanController = TextEditingController();

  String? _selectedAkunId;
  late DateTime _waktu;
  late DateTime _tenggatWaktu;

  // Hapus keyword 'final' agar variabel bisa diatur ulang dengan aman jika diperlukan,
  // atau cukup atur logika inisialisasinya agar hanya berjalan satu arah.
  late DateTime _initialWaktu;
  late DateTime _initialTenggatWaktu;

  @override
  void initState() {
    super.initState();

    if (widget.dataEdit != null) {
      // Logika saat mode Edit
      final d = widget.dataEdit!;
      _nominalController.text = widget.dataEdit!.nominal.toRibuan();
      _pihakController.text = d.pihakTerkait;
      _catatanController.text = d.catatan;
      _selectedAkunId = d.akunId;

      _waktu = d.waktu;
      _tenggatWaktu = d.tenggatWaktu;
      _initialWaktu = d.waktu;
      _initialTenggatWaktu = d.tenggatWaktu;
    } else {
      // Logika saat mode Tambah Baru
      final now = DateTime.now();
      _waktu = now;
      _tenggatWaktu = now.add(const Duration(days: 30));
      _initialWaktu = now;
      _initialTenggatWaktu = now.add(const Duration(days: 30));
    }
  }

  bool _hasChanges() {
    if (widget.dataEdit == null) {
      return _nominalController.text.isNotEmpty ||
          _pihakController.text.isNotEmpty ||
          _catatanController.text.isNotEmpty ||
          _selectedAkunId != null ||
          _waktu != _initialWaktu ||
          _tenggatWaktu != _initialTenggatWaktu;
    } else {
      final d = widget.dataEdit!;
      return _nominalController.text != d.nominal.toRibuan() ||
          _pihakController.text != d.pihakTerkait ||
          _catatanController.text != d.catatan ||
          _selectedAkunId != d.akunId ||
          _waktu != d.waktu ||
          _tenggatWaktu != d.tenggatWaktu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final akunState = ref.watch(akunControllerProvider);

    final isUtang = widget.tipe == TipeUtangPiutang.utang;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasChanges()) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Batalkan perubahan?'),
              content: const Text('Data yang sudah diisi tidak akan disimpan.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Tidak'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Ya, Batalkan'),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isUtang ? 'Tambah Utang' : 'Tambah Piutang'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyFormatter()],
                    maxLength: 11,
                    decoration: const InputDecoration(
                      labelText: 'Nominal (Rp)',
                      prefixText: 'Rp ',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pihakController,
                    maxLength: 30,
                    decoration: InputDecoration(
                      labelText: isUtang
                          ? 'Pihak Pemberi Dana'
                          : 'Pihak Penerima Dana',
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  akunState.maybeWhen(
                    data: (akunList) => DropdownButtonFormField<String>(
                      initialValue: _selectedAkunId,
                      decoration: InputDecoration(
                        labelText: isUtang
                            ? 'Akun untuk Menerima'
                            : 'Akun untuk Memberi',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        ...akunList
                            .where(
                              (a) => !a.isDibekukan || a.id == _selectedAkunId,
                            )
                            .map(
                              (a) => DropdownMenuItem(
                                value: a.id,
                                child: Text(a.nama),
                              ),
                            ),
                        const DropdownMenuItem(
                          value: 'add_new',
                          child: Text(
                            '+ Tambahkan akun',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == 'add_new') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KelolaAkunScreen(),
                            ),
                          );
                          return;
                        }

                        setState(() => _selectedAkunId = val);
                      },
                    ),
                    orElse: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Tanggal & Waktu'),
                    subtitle: Text(
                      '${_waktu.day}/${_waktu.month}/${_waktu.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _waktu,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _waktu = date);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Tenggat Waktu'),
                    subtitle: Text(
                      '${_tenggatWaktu.day}/${_tenggatWaktu.month}/${_tenggatWaktu.year}',
                    ),
                    trailing: const Icon(Icons.event_busy),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _tenggatWaktu,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _tenggatWaktu = date);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _catatanController,
                    maxLength: 64,
                    decoration: const InputDecoration(
                      labelText: 'Catatan / Deskripsi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _simpanData,
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _autoFormatText(String input) {
    String res = input.replaceAll(RegExp(r'[\\/:*?"<>|~#%&{}$]'), '');
    res = res.replaceAll(RegExp(r'\s{2,}'), ' ');
    res = res.replaceFirst(RegExp(r'^\.+'), '');
    res = res.trim();
    if (res.isNotEmpty) {
      res = res[0].toUpperCase() + res.substring(1);
    }
    return res;
  }

  void _simpanData() {
    final pihakFormatted = _autoFormatText(_pihakController.text);
    final catatanFormatted = _autoFormatText(_catatanController.text);

    if (_nominalController.text.isEmpty ||
        pihakFormatted.isEmpty ||
        _selectedAkunId == null ||
        catatanFormatted.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Isi field wajib!')));
      return;
    }

    final nominal = double.parse(_nominalController.text.replaceAll('.', ''));

    final data = UtangPiutangModel(
      id:
          widget.dataEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      tipe: widget.tipe,
      nominal: nominal,
      pihakTerkait: pihakFormatted,
      akunId: _selectedAkunId,
      waktu: _waktu,
      tenggatWaktu: _tenggatWaktu,
      catatan: catatanFormatted,
      isLunas: widget.dataEdit?.isLunas ?? false,
    );

    if (widget.dataEdit != null) {
      ref
          .read(utangPiutangControllerProvider.notifier)
          .updateUtangPiutang(data);
    } else {
      ref
          .read(utangPiutangControllerProvider.notifier)
          .tambahUtangPiutang(data);
    }

    Navigator.pop(context);
  }
}
