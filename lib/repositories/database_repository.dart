import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_helper.dart';
import '../models/transaksi_model.dart';
import '../models/akun_model.dart';
import '../models/label_model.dart';
import '../models/utang_piutang_model.dart';

// Import model label dan utang_piutang jika sudah dibuat

// Provider untuk memudahkan injeksi dependensi di Controller layer
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
      'nominal': transaksi.nominal,
      'biayaTambahan': transaksi.biayaTambahan,
      'kuantitas': transaksi.kuantitas,
      'akunSumberId': transaksi.akunSumberId,
      'akunTujuanId': transaksi.akunTujuanId,
      'labelId': transaksi.labelId,
      'waktu': transaksi.waktu.toIso8601String(),
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
        nominal: maps[i]['nominal'],
        biayaTambahan: maps[i]['biayaTambahan'],
        kuantitas: maps[i]['kuantitas'],
        akunSumberId: maps[i]['akunSumberId'],
        akunTujuanId: maps[i]['akunTujuanId'],
        labelId: maps[i]['labelId'],
        waktu: DateTime.parse(maps[i]['waktu']),
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
        'nominal': transaksi.nominal,
        'biayaTambahan': transaksi.biayaTambahan,
        'kuantitas': transaksi.kuantitas,
        'akunSumberId': transaksi.akunSumberId,
        'akunTujuanId': transaksi.akunTujuanId,
        'labelId': transaksi.labelId,
        'waktu': transaksi.waktu.toIso8601String(),
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
    return await db.insert('akun', {
      'id': akun.id,
      'nama': akun.nama,
      'saldoAwal': akun.saldoAwal,
    });
  }

  Future<List<AkunModel>> getSemuaAkun() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('akun');

    return List.generate(maps.length, (i) {
      return AkunModel(
        id: maps[i]['id'],
        nama: maps[i]['nama'],
        saldoAwal: maps[i]['saldoAwal'],
      );
    });
  }

  Future<int> deleteAkun(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('akun', where: 'id = ?', whereArgs: [id]);
  }

  // ==============================
  // CRUD LABEL
  // ==============================

  Future<int> insertLabel(LabelModel label) async {
    final db = await _dbHelper.database;
    return await db.insert('label', {'id': label.id, 'nama': label.nama});
  }

  Future<List<LabelModel>> getSemuaLabel() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('label');

    return List.generate(maps.length, (i) {
      return LabelModel(id: maps[i]['id'], nama: maps[i]['nama']);
    });
  }

  Future<int> deleteLabel(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('label', where: 'id = ?', whereArgs: [id]);
  }

  // ==============================
  // CRUD UTANG PIUTANG
  // ==============================

  Future<int> insertUtangPiutang(UtangPiutangModel data) async {
    final db = await _dbHelper.database;
    return await db.insert('utang_piutang', {
      'id': data.id,
      'tipe': data.tipe.name,
      'nominal': data.nominal,
      'pihakTerkait': data.pihakTerkait,
      'akunId': data.akunId,
      'waktu': data.waktu.toIso8601String(),
      'tenggatWaktu': data.tenggatWaktu.toIso8601String(),
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
        nominal: maps[i]['nominal'],
        pihakTerkait: maps[i]['pihakTerkait'],
        akunId: maps[i]['akunId'],
        waktu: DateTime.parse(maps[i]['waktu']),
        tenggatWaktu: DateTime.parse(maps[i]['tenggatWaktu']),
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
        'nominal': data.nominal,
        'pihakTerkait': data.pihakTerkait,
        'akunId': data.akunId,
        'waktu': data.waktu.toIso8601String(),
        'tenggatWaktu': data.tenggatWaktu.toIso8601String(),
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
}
