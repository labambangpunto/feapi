import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/akun_controller.dart';
import '../controllers/utang_piutang_controller.dart';
import '../models/utang_piutang_model.dart';
import '../utils/currency_formatter.dart';

import '../utils/currency_format.dart';
import 'kelola_akun_screen.dart';

class FormUtangPiutangScreen extends ConsumerStatefulWidget {
  final TipeUtangPiutang tipe;
  final UtangPiutangModel? dataEdit; // Parameter untuk mode edit

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
          TextField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyFormatter()],
            decoration: const InputDecoration(
              labelText: 'Nominal (Rp)',
              prefixText: 'Rp ',
            ),
          ),
          TextField(
            controller: _pihakController,
            decoration: InputDecoration(
              labelText: isUtang ? 'Pihak Pemberi Dana' : 'Pihak Penerima Dana',
            ),
          ),
          const SizedBox(height: 16),
          akunState.maybeWhen(
            data: (akunList) => DropdownButtonFormField<String>(
              initialValue: _selectedAkunId,
              hint: Text(
                isUtang ? 'Akun untuk Menerima' : 'Akun untuk Memberi',
              ),
              items: [
                ...akunList
                    .where((a) => !a.isDibekukan || a.id == _selectedAkunId)
                    .map((a) {
                      return DropdownMenuItem(value: a.id, child: Text(a.nama));
                    }),
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
                    MaterialPageRoute(builder: (_) => const KelolaAkunScreen()),
                  );
                } else {
                  setState(() => _selectedAkunId = val);
                }
              },
            ),
            orElse: () => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Tanggal & Waktu'),
            subtitle: Text(_waktu.toString().split('.')[0]),
            trailing: const Icon(Icons.calendar_today),
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
          ListTile(
            title: const Text('Tenggat Waktu'),
            subtitle: Text(_tenggatWaktu.toString().split(' ')[0]),
            trailing: const Icon(Icons.event_busy),
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
          TextField(
            controller: _catatanController,
            maxLength: 128, // Tambahkan baris ini
            decoration: const InputDecoration(labelText: 'Catatan / Deskripsi'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _simpanData, child: const Text('Simpan')),
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
    // Terapkan auto-format pada pihak terkait dan catatan
    final pihakFormatted = _autoFormatText(_pihakController.text);
    final catatanFormatted = _autoFormatText(_catatanController.text);

    if (_nominalController.text.isEmpty ||
        pihakFormatted.isEmpty || // Gunakan variabel format untuk cek validasi
        _selectedAkunId == null ||
        catatanFormatted.isEmpty) {
      // Gunakan variabel format untuk cek validasi
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
      pihakTerkait: pihakFormatted, // Gunakan teks yang sudah diformat
      akunId: _selectedAkunId,
      waktu: _waktu,
      tenggatWaktu: _tenggatWaktu,
      catatan: catatanFormatted, // Gunakan teks yang sudah diformat
      isLunas: widget.dataEdit?.isLunas ?? false,
    );
    // ... sisa kode di bawahnya tetap sama

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
