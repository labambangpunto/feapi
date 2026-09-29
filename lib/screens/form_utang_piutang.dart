import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/akun_controller.dart';
import '../controllers/utang_piutang_controller.dart';
import '../models/utang_piutang_model.dart';
import '../utils/currency_formatter.dart';

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
      _nominalController.text = d.nominal.toInt().toString();
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
              items: akunList
                  .map(
                    (a) => DropdownMenuItem(value: a.id, child: Text(a.nama)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedAkunId = val),
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
            decoration: const InputDecoration(labelText: 'Catatan / Deskripsi'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _simpanData, child: const Text('Simpan')),
        ],
      ),
    );
  }

  void _simpanData() {
    if (_nominalController.text.isEmpty ||
        _pihakController.text.isEmpty ||
        _selectedAkunId == null ||
        _catatanController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Isi field wajib!')));
      return;
    }

    final nominal = double.parse(_nominalController.text.replaceAll('.', ''));
    final data = UtangPiutangModel(
      id:
          widget.dataEdit?.id ??
          DateTime.now().millisecondsSinceEpoch
              .toString(), // Gunakan ID lama jika edit
      tipe: widget.tipe,
      nominal: nominal,
      pihakTerkait: _pihakController.text,
      akunId: _selectedAkunId,
      waktu: _waktu,
      tenggatWaktu: _tenggatWaktu,
      catatan: _catatanController.text,
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
