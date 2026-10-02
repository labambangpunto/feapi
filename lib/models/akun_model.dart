class AkunModel {
  final String id;
  final String nama;
  final bool isDibekukan;

  AkunModel({
    required this.id,
    required this.nama,
    this.isDibekukan = false, // Default false agar akun baru otomatis aktif
  });

  // Konversi objek ke Map untuk disimpan di SQLite
  Map<String, dynamic> toMap() {
    return {'id': id, 'nama': nama, 'isDibekukan': isDibekukan ? 1 : 0};
  }

  // Konversi Map dari SQLite menjadi objek AkunModel
  factory AkunModel.fromMap(Map<String, dynamic> map) {
    return AkunModel(
      id: map['id'],
      nama: map['nama'],
      isDibekukan: map['isDibekukan'] == 1,
    );
  }

  // Membuat salinan objek dengan nilai yang diperbarui
  AkunModel copyWith({String? id, String? nama, bool? isDibekukan}) {
    return AkunModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      isDibekukan: isDibekukan ?? this.isDibekukan,
    );
  }
}
