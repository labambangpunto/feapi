class PembukuanModel {
  final String id;
  final int tahun;
  final int bulan;
  final bool isTerkunci;

  PembukuanModel({
    required this.id,
    required this.tahun,
    required this.bulan,
    this.isTerkunci = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tahun': tahun,
      'bulan': bulan,
      'isTerkunci': isTerkunci ? 1 : 0,
    };
  }

  factory PembukuanModel.fromMap(Map<String, dynamic> map) {
    return PembukuanModel(
      id: map['id'],
      tahun: map['tahun'],
      bulan: map['bulan'],
      isTerkunci: map['isTerkunci'] == 1,
    );
  }
}
