import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
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
  DateTime _waktu = DateTime.now();
  DateTime _tenggatWaktu = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    if (widget.dataEdit != null) {
      final d = widget.dataEdit!;
      _nominalController.text = widget.dataEdit!.nominal.toRibuan();
      _pihakController.text = d.pihakTerkait;
      _catatanController.text = d.catatan;
      _selectedAkunId = d.akunId;
      _waktu = d.waktu;
      _tenggatWaktu = d.tenggatWaktu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final akunState = ref.watch(akunControllerProvider);

    final isUtang = widget.tipe == TipeUtangPiutang.utang;

    return Scaffold(
      appBar: AppBar(title: Text(isUtang ? 'Tambah Utang' : 'Tambah Piutang')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          M3ETextField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyFormatter()],
            label: 'Nominal (Rp)',
            prefixText: 'Rp ',
          ),
          const SizedBox(height: 12),
          M3ETextField(
            controller: _pihakController,
            label: isUtang ? 'Pihak Pemberi Dana' : 'Pihak Penerima Dana',
          ),
          const SizedBox(height: 16),
          akunState.maybeWhen(
            data: (akunList) => M3EDropdownMenu<String>(
              singleSelect: true,
              fieldStyle: M3EDropdownFieldStyle(
                hintText: isUtang
                    ? 'Akun untuk Menerima'
                    : 'Akun untuk Memberi',
              ),
              items: [
                ...akunList
                    .where((a) => !a.isDibekukan || a.id == _selectedAkunId)
                    .map((a) => M3EDropdownItem(label: a.nama, value: a.id)),
                const M3EDropdownItem(
                  label: '+ Tambahkan akun',
                  value: 'add_new',
                ),
              ],
              onSelectionChanged: (items) {
                final val = items.isEmpty ? null : items.first.value;

                if (val == 'add_new') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KelolaAkunScreen()),
                  );
                  return;
                }

                setState(() => _selectedAkunId = val);
              },
            ),
            orElse: () => const M3EProgressIndicator.circular(),
          ),
          const SizedBox(height: 16),
          M3EListItem(
            headline: 'Tanggal & Waktu',
            supportingText: '${_waktu.day}/${_waktu.month}/${_waktu.year}',
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await M3EDatePicker.show(
                context,
                initialDate: _waktu,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _waktu = date);
            },
          ),
          const SizedBox(height: 8),
          M3EListItem(
            headline: 'Tenggat Waktu',
            supportingText:
                '${_tenggatWaktu.day}/${_tenggatWaktu.month}/${_tenggatWaktu.year}',
            trailing: const Icon(Icons.event_busy),
            onTap: () async {
              final date = await M3EDatePicker.show(
                context,
                initialDate: _tenggatWaktu,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _tenggatWaktu = date);
            },
          ),
          const SizedBox(height: 12),
          M3ETextField(
            controller: _catatanController,
            label: 'Catatan / Deskripsi',
          ),
          const SizedBox(height: 24),
          M3EButton.filled(onPressed: _simpanData, child: const Text('Simpan')),
        ],
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
      M3ESnackbar.show(context, message: 'Isi field wajib!');
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
