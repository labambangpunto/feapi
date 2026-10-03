import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database_helper.dart';
import '../models/transaksi_model.dart';
import '../models/akun_model.dart';
import '../models/label_model.dart';
import '../models/utang_piutang_model.dart';

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return DatabaseRepository();
});

class DatabaseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ==============================
  // CRUD TRANSAKSI
  // ==============================

  Future<int> insertTransaksi(TransaksiModel transaksi) async {
    final db = await _dbHelper.database;
    return await db.insert('transaksi', {
      'id': transaksi.id,
      'tipe': transaksi.tipe.name,
      'nominal': transaksi.nominal.toInt(), // Konversi ke INTEGER
      'biayaTambahan': transaksi.biayaTambahan?.toInt(), // Konversi ke INTEGER
      'kuantitas': transaksi.kuantitas,
      'akunSumberId': transaksi.akunSumberId,
      'akunTujuanId': transaksi.akunTujuanId,
      'labelId': transaksi.labelId,
      'waktu': transaksi.waktu.millisecondsSinceEpoch, // Konversi ke Epoch
      'catatan': transaksi.catatan,
    });
  }

  Future<List<TransaksiModel>> getSemuaTransaksi() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaksi',
      orderBy: 'waktu DESC',
    );

    return List.generate(maps.length, (i) {
      return TransaksiModel(
        id: maps[i]['id'],
        tipe: TipeTransaksi.values.byName(maps[i]['tipe']),
        // Casting aman dari INTEGER SQLite kembali ke double Dart
        nominal: (maps[i]['nominal'] as num).toDouble(),
        biayaTambahan: maps[i]['biayaTambahan'] != null
            ? (maps[i]['biayaTambahan'] as num).toDouble()
            : null,
        kuantitas: maps[i]['kuantitas'],
        akunSumberId: maps[i]['akunSumberId'],
        akunTujuanId: maps[i]['akunTujuanId'],
        labelId: maps[i]['labelId'],
        // Parsing kembali dari Epoch ke DateTime
        waktu: DateTime.fromMillisecondsSinceEpoch(maps[i]['waktu'] as int),
        catatan: maps[i]['catatan'],
      );
    });
  }

  Future<int> updateTransaksi(TransaksiModel transaksi) async {
    final db = await _dbHelper.database;
    return await db.update(
      'transaksi',
      {
        'tipe': transaksi.tipe.name,
        'nominal': transaksi.nominal.toInt(),
        'biayaTambahan': transaksi.biayaTambahan?.toInt(),
        'kuantitas': transaksi.kuantitas,
        'akunSumberId': transaksi.akunSumberId,
        'akunTujuanId': transaksi.akunTujuanId,
        'labelId': transaksi.labelId,
        'waktu': transaksi.waktu.millisecondsSinceEpoch,
        'catatan': transaksi.catatan,
      },
      where: 'id = ?',
      whereArgs: [transaksi.id],
    );
  }

  Future<int> deleteTransaksi(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }

  // ==============================
  // CRUD AKUN
  // ==============================

  Future<int> insertAkun(AkunModel akun) async {
    final db = await _dbHelper.database;
    return await db.insert('akun', akun.toMap());
  }

  Future<List<AkunModel>> getSemuaAkun() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('akun');

    return List.generate(maps.length, (i) {
      return AkunModel.fromMap(maps[i]);
    });
  }

  Future<int> deleteAkun(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('akun', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAkun(AkunModel akun) async {
    final db = await _dbHelper.database;
    return await db.update(
      'akun',
      akun.toMap(),
      where: 'id = ?',
      whereArgs: [akun.id],
    );
  }

  // ==============================
  // CRUD LABEL
  // ==============================

  Future<int> insertLabel(LabelModel label) async {
    final db = await _dbHelper.database;
    return await db.insert('label', label.toMap());
  }

  Future<List<LabelModel>> getSemuaLabel() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('label');

    bool hasUtang = maps.any((m) => m['id'] == 'label_utang');
    bool hasPiutang = maps.any((m) => m['id'] == 'label_piutang');

    if (!hasUtang) {
      final labelUtang = LabelModel(
        id: 'label_utang',
        nama: 'Utang',
        isDibekukan: false,
      );
      await db.insert('label', labelUtang.toMap());
    }
    if (!hasPiutang) {
      final labelPiutang = LabelModel(
        id: 'label_piutang',
        nama: 'Piutang',
        isDibekukan: false,
      );
      await db.insert('label', labelPiutang.toMap());
    }

    final List<Map<String, dynamic>> finalMaps = (!hasUtang || !hasPiutang)
        ? await db.query('label')
        : maps;

    return List.generate(finalMaps.length, (i) {
      return LabelModel.fromMap(finalMaps[i]);
    });
  }

  Future<int> deleteLabel(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('label', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateLabel(LabelModel label) async {
    final db = await _dbHelper.database;
    return await db.update(
      'label',
      label.toMap(),
      where: 'id = ?',
      whereArgs: [label.id],
    );
  }

  // ==============================
  // CRUD UTANG PIUTANG
  // ==============================

  Future<int> insertUtangPiutang(UtangPiutangModel data) async {
    final db = await _dbHelper.database;
    return await db.insert('utang_piutang', {
      'id': data.id,
      'tipe': data.tipe.name,
      'nominal': data.nominal.toInt(),
      'pihakTerkait': data.pihakTerkait,
      'akunId': data.akunId,
      'waktu': data.waktu.millisecondsSinceEpoch,
      'tenggatWaktu': data.tenggatWaktu.millisecondsSinceEpoch,
      'catatan': data.catatan,
      'isLunas': data.isLunas ? 1 : 0,
    });
  }

  Future<List<UtangPiutangModel>> getSemuaUtangPiutang() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'utang_piutang',
      orderBy: 'waktu DESC',
    );

    return List.generate(maps.length, (i) {
      return UtangPiutangModel(
        id: maps[i]['id'],
        tipe: TipeUtangPiutang.values.byName(maps[i]['tipe']),
        nominal: (maps[i]['nominal'] as num).toDouble(),
        pihakTerkait: maps[i]['pihakTerkait'],
        akunId: maps[i]['akunId'],
        waktu: DateTime.fromMillisecondsSinceEpoch(maps[i]['waktu'] as int),
        tenggatWaktu: DateTime.fromMillisecondsSinceEpoch(
          maps[i]['tenggatWaktu'] as int,
        ),
        catatan: maps[i]['catatan'],
        isLunas: maps[i]['isLunas'] == 1,
      );
    });
  }

  Future<int> updateUtangPiutang(UtangPiutangModel data) async {
    final db = await _dbHelper.database;
    return await db.update(
      'utang_piutang',
      {
        'tipe': data.tipe.name,
        'nominal': data.nominal.toInt(),
        'pihakTerkait': data.pihakTerkait,
        'akunId': data.akunId,
        'waktu': data.waktu.millisecondsSinceEpoch,
        'tenggatWaktu': data.tenggatWaktu.millisecondsSinceEpoch,
        'catatan': data.catatan,
        'isLunas': data.isLunas ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  Future<int> deleteUtangPiutang(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('utang_piutang', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetDatabase() async {
    await _dbHelper.resetSeluruhDatabase();
  }

  // ==============================
  // BUAT PROFIL YGY
  // ==============================

  Future<Map<String, dynamic>?> getProfil() async {
    final db = await _dbHelper.database;
    final result = await db.query('profil', where: 'id = 1');
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> saveProfil(String nama, String? fotoBase64) async {
    final db = await _dbHelper.database;
    await db.insert('profil', {
      'id': 1,
      'nama': nama,
      'fotoBase64': fotoBase64,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
