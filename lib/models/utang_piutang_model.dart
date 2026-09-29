enum TipeUtangPiutang { utang, piutang }

class UtangPiutangModel {
  final String id;
  final TipeUtangPiutang tipe;
  final double nominal;
  final String pihakTerkait;
  final String? akunId;
  final DateTime waktu;
  final DateTime tenggatWaktu;
  final String catatan;
  final bool isLunas;

  UtangPiutangModel({
    required this.id,
    required this.tipe,
    required this.nominal,
    required this.pihakTerkait,
    this.akunId,
    required this.waktu,
    required this.tenggatWaktu,
    required this.catatan,
    this.isLunas = false,
  });
}
