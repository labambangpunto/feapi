import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/akun_controller.dart';
import '../controllers/label_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../models/transaksi_model.dart';
import '../utils/currency_formatter.dart';
import '../controllers/summary_provider.dart';

class FormTransaksiScreen extends ConsumerStatefulWidget {
  final TipeTransaksi tipeTransaksi;
  final TransaksiModel? dataEdit; // Tambahan untuk mode edit

  const FormTransaksiScreen({
    super.key,
    required this.tipeTransaksi,
    this.dataEdit,
  });

  @override
  ConsumerState<FormTransaksiScreen> createState() =>
      _FormTransaksiScreenState();
}

class _FormTransaksiScreenState extends ConsumerState<FormTransaksiScreen> {
  final _nominalController = TextEditingController();
  final _biayaTambahanController = TextEditingController();
  final _kuantitasController = TextEditingController(text: '1');
  final _catatanController = TextEditingController();

  String? _selectedAkunSumberId;
  String? _selectedAkunTujuanId;
  String? _selectedLabelId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Mengisi form jika ada dataEdit
    if (widget.dataEdit != null) {
      final d = widget.dataEdit!;
      _nominalController.text = d.nominal.toInt().toString();
      if (d.biayaTambahan != null) {
        _biayaTambahanController.text = d.biayaTambahan!.toInt().toString();
      }
      _kuantitasController.text = d.kuantitas.toString();
      _catatanController.text = d.catatan;
      _selectedAkunSumberId = d.akunSumberId;
      _selectedAkunTujuanId = d.akunTujuanId;
      _selectedLabelId = d.labelId;
      _selectedDate = d.waktu;
    }
  }

  @override
  Widget build(BuildContext context) {
    final akunState = ref.watch(akunControllerProvider);
    final labelState = ref.watch(labelControllerProvider);

    final isPengeluaran = widget.tipeTransaksi == TipeTransaksi.pengeluaran;
    final isPemasukan = widget.tipeTransaksi == TipeTransaksi.pemasukan;
    final isTransfer = widget.tipeTransaksi == TipeTransaksi.transfer;

    String title = isPengeluaran
        ? 'Form Pengeluaran'
        : (isPemasukan ? 'Form Pemasukan' : 'Form Transfer');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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

          if (isPengeluaran || isTransfer)
            TextField(
              controller: _biayaTambahanController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyFormatter()],
              decoration: const InputDecoration(
                labelText: 'Biaya Tambahan (Opsional)',
                prefixText: 'Rp ',
              ),
            ),

          if (isPengeluaran)
            TextField(
              controller: _kuantitasController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kuantitas (Qty)'),
            ),

          const SizedBox(height: 16),
          akunState.maybeWhen(
            data: (akunList) => Column(
              children: [
                if (isPengeluaran || isTransfer)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAkunSumberId,
                    hint: const Text('Akun Sumber'),
                    items: akunList
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.nama),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedAkunSumberId = val),
                  ),
                if (isTransfer) const SizedBox(height: 16),
                if (isPemasukan || isTransfer)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAkunTujuanId,
                    hint: const Text('Akun Tujuan'),
                    items: akunList
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.nama),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedAkunTujuanId = val),
                  ),
              ],
            ),
            orElse: () => const CircularProgressIndicator(),
          ),

          const SizedBox(height: 16),
          labelState.maybeWhen(
            data: (labelList) => Wrap(
              spacing: 8,
              children: labelList
                  .map(
                    (l) => ChoiceChip(
                      label: Text(l.nama),
                      selected: _selectedLabelId == l.id,
                      onSelected: (selected) => setState(
                        () => _selectedLabelId = selected ? l.id : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
            orElse: () => const CircularProgressIndicator(),
          ),

          const SizedBox(height: 16),
          ListTile(
            title: const Text('Tanggal & Waktu'),
            subtitle: Text(_selectedDate.toString()),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
          TextField(
            controller: _catatanController,
            decoration: const InputDecoration(labelText: 'Catatan / Deskripsi'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _simpanTransaksi,
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _simpanTransaksi() {
    if (_nominalController.text.isEmpty ||
        (_selectedAkunSumberId == null &&
            widget.tipeTransaksi != TipeTransaksi.pemasukan) ||
        (_selectedAkunTujuanId == null &&
            widget.tipeTransaksi == TipeTransaksi.transfer)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Isi field wajib!')));
      return;
    }

    final nominal = double.parse(_nominalController.text.replaceAll('.', ''));
    final biayaTambahan = _biayaTambahanController.text.isNotEmpty
        ? double.parse(_biayaTambahanController.text.replaceAll('.', ''))
        : null;
    final qty = int.parse(_kuantitasController.text);

    // Validasi pencegahan saldo minus
    if (widget.tipeTransaksi == TipeTransaksi.pengeluaran ||
        widget.tipeTransaksi == TipeTransaksi.transfer) {
      final summary = ref.read(summaryProvider);
      double saldoTersedia = summary.saldoPerAkun[_selectedAkunSumberId] ?? 0;

      // Jika dalam mode edit, kembalikan sementara nominal lama ke saldo tersedia agar kalkulasi akurat
      if (widget.dataEdit != null &&
          widget.dataEdit!.akunSumberId == _selectedAkunSumberId) {
        saldoTersedia +=
            (widget.dataEdit!.nominal * widget.dataEdit!.kuantitas) +
            (widget.dataEdit!.biayaTambahan ?? 0);
      }

      final totalBeban = (nominal * qty) + (biayaTambahan ?? 0);

      if (totalBeban > saldoTersedia) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peringatan: Saldo tidak cukup!')),
        );
        return; // Hentikan penyimpanan
      }
    }

    final transaksi = TransaksiModel(
      id:
          widget.dataEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      tipe: widget.tipeTransaksi,
      nominal: nominal,
      biayaTambahan: biayaTambahan,
      kuantitas: qty,
      akunSumberId: _selectedAkunSumberId,
      akunTujuanId: _selectedAkunTujuanId,
      labelId: _selectedLabelId,
      waktu: _selectedDate,
      catatan: _catatanController.text,
    );

    if (widget.dataEdit != null) {
      ref.read(transaksiControllerProvider.notifier).updateTransaksi(transaksi);
    } else {
      ref.read(transaksiControllerProvider.notifier).tambahTransaksi(transaksi);
    }

    Navigator.pop(context);
  }
}
