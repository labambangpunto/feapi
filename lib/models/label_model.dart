class LabelModel {
  final String id;
  final String nama;
  final bool isDibekukan;

  LabelModel({required this.id, required this.nama, this.isDibekukan = false});

  Map<String, dynamic> toMap() {
    return {'id': id, 'nama': nama, 'isDibekukan': isDibekukan ? 1 : 0};
  }

  factory LabelModel.fromMap(Map<String, dynamic> map) {
    return LabelModel(
      id: map['id'],
      nama: map['nama'],
      isDibekukan: map['isDibekukan'] == 1,
    );
  }

  LabelModel copyWith({String? id, String? nama, bool? isDibekukan}) {
    return LabelModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      isDibekukan: isDibekukan ?? this.isDibekukan,
    );
  }
}
