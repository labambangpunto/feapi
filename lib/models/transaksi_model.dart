enum TipeTransaksi { pengeluaran, pemasukan, transfer }

class TransaksiModel {
  final String id;
  final TipeTransaksi tipe;
  final double nominal;
  final double? biayaTambahan;
  final int kuantitas;
  final String? akunSumberId;
  final String? akunTujuanId;
  final String? labelId;
  final DateTime waktu;
  final String catatan;

  TransaksiModel({
    required this.id,
    required this.tipe,
    required this.nominal,
    this.biayaTambahan,
    this.kuantitas = 1,
    this.akunSumberId,
    this.akunTujuanId,
    this.labelId,
    required this.waktu,
    required this.catatan,
  });
}
