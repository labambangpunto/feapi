import 'package:material_ui/material_ui.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/akun_controller.dart';
import '../controllers/label_controller.dart';
import '../controllers/transaksi_controller.dart';
import '../models/transaksi_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/currency_format.dart';
import 'kelola_akun_screen.dart';
import 'kelola_label_screen.dart';

class FormTransaksiScreen extends ConsumerStatefulWidget {
  final TipeTransaksi tipeTransaksi;
  final TransaksiModel? dataEdit;

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
  List<String> _selectedLabelIds = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.dataEdit != null) {
      final d = widget.dataEdit!;
      _nominalController.text = widget.dataEdit!.nominal.toRibuan();
      if (widget.dataEdit!.biayaTambahan != null) {
        _biayaTambahanController.text = widget.dataEdit!.biayaTambahan!
            .toRibuan();
      }
      _kuantitasController.text = d.kuantitas.toString();
      _catatanController.text = d.catatan;
      _selectedAkunSumberId = d.akunSumberId;
      _selectedAkunTujuanId = d.akunTujuanId;

      if (d.labelId != null && d.labelId!.isNotEmpty) {
        _selectedLabelIds = d.labelId!.split(',');
      }

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
          M3ETextField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyFormatter()],
            label: 'Nominal (Rp)',
            prefixText: 'Rp ',
          ),
          if (isPengeluaran || isTransfer) ...[
            const SizedBox(height: 12),
            M3ETextField(
              controller: _biayaTambahanController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyFormatter()],
              label: 'Biaya Tambahan (Opsional)',
              prefixText: 'Rp ',
            ),
          ],
          if (isPengeluaran) ...[
            const SizedBox(height: 12),
            M3ETextField(
              controller: _kuantitasController,
              keyboardType: TextInputType.number,
              label: 'Kuantitas (Qty)',
            ),
          ],
          const SizedBox(height: 16),
          akunState.maybeWhen(
            data: (akunList) => Column(
              children: [
                if (isPengeluaran || isTransfer)
                  M3EDropdownMenu<String>(
                    singleSelect: true,
                    fieldStyle: const M3EDropdownFieldStyle(
                      hintText: 'Akun Sumber',
                    ),
                    items: [
                      ...akunList
                          .where(
                            (a) =>
                                !a.isDibekukan || a.id == _selectedAkunSumberId,
                          )
                          .map(
                            (a) => M3EDropdownItem(label: a.nama, value: a.id),
                          ),
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
                          MaterialPageRoute(
                            builder: (_) => const KelolaAkunScreen(),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _selectedAkunSumberId = val;
                        if (widget.tipeTransaksi == TipeTransaksi.transfer &&
                            _selectedAkunTujuanId == val) {
                          _selectedAkunTujuanId = null;
                        }
                      });
                    },
                  ),
                if (isTransfer) const SizedBox(height: 16),
                if (isPemasukan || isTransfer)
                  M3EDropdownMenu<String>(
                    singleSelect: true,
                    fieldStyle: const M3EDropdownFieldStyle(
                      hintText: 'Akun Tujuan',
                    ),
                    items: [
                      ...akunList
                          .where(
                            (a) =>
                                !a.isDibekukan || a.id == _selectedAkunTujuanId,
                          )
                          .map(
                            (a) => M3EDropdownItem(label: a.nama, value: a.id),
                          ),
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
                          MaterialPageRoute(
                            builder: (_) => const KelolaAkunScreen(),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _selectedAkunTujuanId = val;
                        // Reset akun sumber jika sama dengan akun tujuan
                        if (widget.tipeTransaksi == TipeTransaksi.transfer &&
                            _selectedAkunSumberId == val) {
                          _selectedAkunSumberId = null;
                        }
                      });
                    },
                  ),
              ],
            ),
            orElse: () => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          labelState.maybeWhen(
            data: (labelList) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...labelList
                    .where(
                      (l) => !l.isDibekukan || _selectedLabelIds.contains(l.id),
                    )
                    .map(
                      (l) => M3EChip(
                        label: l.nama,
                        type: M3EChipType.filter,
                        selected: _selectedLabelIds.contains(l.id),
                        onPressed: () {
                          setState(() {
                            if (_selectedLabelIds.contains(l.id)) {
                              _selectedLabelIds.remove(l.id);
                            } else {
                              _selectedLabelIds.add(l.id);
                            }
                          });
                        },
                      ),
                    ),
                M3EChip(
                  label: 'Tambah',
                  leading: const Icon(Icons.add, size: 16),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KelolaLabelScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            orElse: () => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          M3EListItem(
            headline: 'Tanggal & Waktu',
            supportingText:
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await M3EDatePicker.show(
                context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 12),
          M3ETextField(
            controller: _catatanController,
            label: 'Catatan / Deskripsi',
          ),
          const SizedBox(height: 24),
          M3EButton.filled(
            onPressed: _simpanTransaksi,
            child: const Text('Simpan'),
          ),
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

  void _simpanTransaksi() {
    if (_nominalController.text.isEmpty ||
        (_selectedAkunSumberId == null &&
            widget.tipeTransaksi != TipeTransaksi.pemasukan) ||
        (_selectedAkunTujuanId == null &&
            widget.tipeTransaksi == TipeTransaksi.transfer) ||
        _selectedLabelIds.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Isi field wajib!')));
      return;
    }
    if (widget.tipeTransaksi == TipeTransaksi.transfer &&
        _selectedAkunSumberId == _selectedAkunTujuanId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun sumber dan tujuan tidak boleh sama!'),
        ),
      );
      return;
    }

    final nominal = double.parse(_nominalController.text.replaceAll('.', ''));
    final biayaTambahan = _biayaTambahanController.text.isNotEmpty
        ? double.parse(_biayaTambahanController.text.replaceAll('.', ''))
        : null;
    final qty = int.parse(_kuantitasController.text);

    final catatanFormatted = _autoFormatText(_catatanController.text);

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
      labelId: _selectedLabelIds.join(','),
      waktu: _selectedDate,
      catatan: catatanFormatted,
    );

    if (widget.dataEdit != null) {
      ref.read(transaksiControllerProvider.notifier).updateTransaksi(transaksi);
    } else {
      ref.read(transaksiControllerProvider.notifier).tambahTransaksi(transaksi);
    }

    Navigator.pop(context);
  }
}
