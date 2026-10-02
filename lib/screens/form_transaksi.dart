import 'package:flutter/material.dart';
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
  List<String> _selectedLabelIds = []; // Tambahkan ini
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

      // Pisahkan ID label dengan koma jika ada
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
                    items: [
                      ...akunList
                          .where(
                            (a) =>
                                !a.isDibekukan || a.id == _selectedAkunSumberId,
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
                      } else {
                        setState(() {
                          _selectedAkunSumberId = val;
                          // Reset akun tujuan jika sama dengan akun sumber
                          if (widget.tipeTransaksi == TipeTransaksi.transfer &&
                              _selectedAkunTujuanId == val) {
                            _selectedAkunTujuanId = null;
                          }
                        });
                      }
                    },
                  ),
                if (isTransfer) const SizedBox(height: 16),
                if (isPemasukan || isTransfer)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAkunTujuanId,
                    hint: const Text('Akun Tujuan'),
                    items: [
                      ...akunList
                          .where(
                            (a) =>
                                !a.isDibekukan || a.id == _selectedAkunTujuanId,
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
                      } else {
                        setState(() {
                          _selectedAkunTujuanId = val;
                          // Reset akun sumber jika sama dengan akun tujuan
                          if (widget.tipeTransaksi == TipeTransaksi.transfer &&
                              _selectedAkunSumberId == val) {
                            _selectedAkunSumberId = null;
                          }
                        });
                      }
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
              children: [
                ...labelList
                    .where(
                      (l) => !l.isDibekukan || _selectedLabelIds.contains(l.id),
                    )
                    .map(
                      // Gunakan FilterChip alih-alih ChoiceChip
                      (l) => FilterChip(
                        label: Text(l.nama),
                        selected: _selectedLabelIds.contains(l.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedLabelIds.add(l.id);
                            } else {
                              _selectedLabelIds.remove(l.id);
                            }
                          });
                        },
                      ),
                    ),
                ActionChip(
                  label: const Text('+ Tambah'),
                  avatar: const Icon(Icons.add, size: 16),
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
            maxLength: 128, // Tambahkan baris ini
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

  String _autoFormatText(String input) {
    // 5. Hapus karakter terlarang
    String res = input.replaceAll(RegExp(r'[\\/:*?"<>|~#%&{}$]'), '');
    // 4. Hapus spasi ganda
    res = res.replaceAll(RegExp(r'\s{2,}'), ' ');
    // 3. Hapus titik di awal teks
    res = res.replaceFirst(RegExp(r'^\.+'), '');
    // 2. Hapus spasi di awal dan akhir
    res = res.trim();
    // 1. Huruf pertama otomatis kapital
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
      // Ubah validasi label menjadi ini
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

    // Terapkan auto-format pada catatan
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
      labelId: _selectedLabelIds.join(','), // Gabungkan ID dengan koma
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
