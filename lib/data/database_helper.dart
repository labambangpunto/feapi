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
    // Inisialisasi FFI untuk dukungan Linux dan Windows
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullType = 'TEXT';
    const realType = 'REAL NOT NULL';
    const realNullType = 'REAL';
    const intType = 'INTEGER NOT NULL';

    // Tabel Akun
    await db.execute('''
  CREATE TABLE akun(
    id TEXT PRIMARY KEY,
    nama TEXT
  )
''');

    // Tabel Label
    await db.execute('''
    CREATE TABLE label (
      id $idType,
      nama $textType
    )
    ''');

    // Tabel Transaksi
    await db.execute('''
    CREATE TABLE transaksi (
      id $idType,
      tipe $textType,
      nominal $realType,
      biayaTambahan $realNullType,
      kuantitas $intType,
      akunSumberId $textNullType,
      akunTujuanId $textNullType,
      labelId $textNullType,
      waktu $textType,
      catatan $textType,
      FOREIGN KEY (akunSumberId) REFERENCES akun (id),
      FOREIGN KEY (akunTujuanId) REFERENCES akun (id),
      FOREIGN KEY (labelId) REFERENCES label (id)
    )
    ''');

    // Tabel Utang Piutang
    await db.execute('''
    CREATE TABLE utang_piutang (
      id $idType,
      tipe $textType,
      nominal $realType,
      pihakTerkait $textType,
      akunId $textNullType,
      waktu $textType,
      tenggatWaktu $textType,
      catatan $textType,
      isLunas $intType,
      FOREIGN KEY (akunId) REFERENCES akun (id)
    )
    ''');
  }

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
