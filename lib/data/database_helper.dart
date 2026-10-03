import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('feapi_app_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullType = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const intNullType = 'INTEGER';

    await db.execute('''
    CREATE TABLE akun(
      id $idType,
      nama $textType,
      isDibekukan INTEGER DEFAULT 0
    )
    ''');

    await db.execute('''
    CREATE TABLE label (
      id $idType,
      nama $textType,
      isDibekukan INTEGER DEFAULT 0
    )
    ''');

    await db.execute('''
    CREATE TABLE transaksi (
      id $idType,
      tipe $textType,
      nominal $intType,
      biayaTambahan $intNullType,
      kuantitas $intType,
      akunSumberId $textNullType,
      akunTujuanId $textNullType,
      labelId $textNullType,
      waktu $intType,
      catatan $textType,
      FOREIGN KEY (akunSumberId) REFERENCES akun (id) ON DELETE SET NULL,
      FOREIGN KEY (akunTujuanId) REFERENCES akun (id) ON DELETE SET NULL,
      FOREIGN KEY (labelId) REFERENCES label (id) ON DELETE SET NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE utang_piutang (
      id $idType,
      tipe $textType,
      nominal $intType,
      pihakTerkait $textType,
      akunId $textNullType,
      waktu $intType,
      tenggatWaktu $intType,
      catatan $textType,
      isLunas $intType,
      FOREIGN KEY (akunId) REFERENCES akun (id) ON DELETE SET NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE profil (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      nama TEXT,
      fotoBase64 TEXT
    )
    ''');

    // PEMBUATAN INDEKS YANG DIREVISI
    // Menghapus indeks transaksi(tipe) dan menambahkan transaksi(labelId)
    await db.execute('CREATE INDEX idx_transaksi_waktu ON transaksi(waktu)');
    await db.execute(
      'CREATE INDEX idx_transaksi_akun_sumber ON transaksi(akunSumberId)',
    );
    await db.execute(
      'CREATE INDEX idx_transaksi_akun_tujuan ON transaksi(akunTujuanId)',
    );
    await db.execute('CREATE INDEX idx_transaksi_label ON transaksi(labelId)');

    // Menghapus indeks utang_piutang(isLunas)
    await db.execute('CREATE INDEX idx_up_waktu ON utang_piutang(waktu)');
    await db.execute('CREATE INDEX idx_up_akun ON utang_piutang(akunId)');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> resetSeluruhDatabase() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('transaksi');
      await txn.delete('utang_piutang');
      await txn.delete('akun');
      await txn.delete('label');
    });
  }
}
