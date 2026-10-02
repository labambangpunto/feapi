import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../repositories/database_repository.dart';
import '../models/akun_model.dart';
import '../models/label_model.dart';
import '../models/transaksi_model.dart';
import '../models/utang_piutang_model.dart';

class BackupService {
  final DatabaseRepository _dbRepo;

  BackupService(this._dbRepo);

  Future<String> _generateCsvString() async {
    final transaksi = await _dbRepo.getSemuaTransaksi();
    List<List<dynamic>> rows = [
      [
        'ID',
        'Tipe',
        'Nominal',
        'Biaya Tambahan',
        'Kuantitas',
        'Akun Sumber',
        'Akun Tujuan',
        'Label',
        'Waktu',
        'Catatan',
      ],
    ];

    for (var t in transaksi) {
      rows.add([
        t.id,
        t.tipe.name,
        t.nominal,
        t.biayaTambahan ?? 0,
        t.kuantitas,
        t.akunSumberId ?? '',
        t.akunTujuanId ?? '',
        t.labelId ?? '',
        t.waktu.toIso8601String(),
        t.catatan,
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  // ==============================
  // EKSPOR CSV
  // ==============================
  Future<String?> simpanCsvKeFolder() async {
    final csvData = await _generateCsvString();
    final bytes = Uint8List.fromList(utf8.encode(csvData));

    // file_picker v13+ akan otomatis menulis 'bytes' ke lokasi yang dipilih
    Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Simpan file CSV',
      fileName: 'feapi_app_data.csv',
      bytes: bytes,
    );

    // Mengembalikan properti path dari Uri sebagai String
    return outputFile?.path;
  }

  Future<void> bagikanCsvLangsung() async {
    final csvData = await _generateCsvString();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/feapi_app_data.csv');

    await file.writeAsString(csvData);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Data CSV Feapi App'),
    );
  }

  // ==============================
  // BACKUP JSON & ENKRIPSI
  // ==============================
  Future<String?> simpanBackupKeFolder(String password) async {
    final finalData = await generateEncryptedJson(password);
    final bytes = Uint8List.fromList(utf8.encode(finalData));

    // file_picker v13+ akan otomatis menulis 'bytes' ke lokasi yang dipilih
    Uri? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Simpan file backup',
      fileName: 'feapi_app_data.enc',
      bytes: bytes,
    );

    // Mengembalikan properti path dari Uri sebagai String
    return outputFile?.path;
  }

  Future<void> bagikanBackupLangsung(String password) async {
    final finalData = await generateEncryptedJson(password);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/feapi_app_data.enc');

    await file.writeAsString(finalData);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Backup Feapi App'),
    );
  }

  Future<void> restoreJsonLokal(String password) async {
    final result = await FilePicker.pickFile();
    if (result == null || result.path == null) return;

    final file = File(result.path!);
    final content = await file.readAsString();
    await restoreFromEncryptedString(content, password);
  }

  // Menghasilkan string JSON terenkripsi
  Future<String> generateEncryptedJson(String password) async {
    final akun = await _dbRepo.getSemuaAkun();
    final label = await _dbRepo.getSemuaLabel();
    final transaksi = await _dbRepo.getSemuaTransaksi();
    final utang = await _dbRepo.getSemuaUtangPiutang();
    final profil = await _dbRepo.getProfil();

    final Map<String, dynamic> seluruhData = {
      'akun': akun.map((e) => {'id': e.id, 'nama': e.nama}).toList(),
      'profil': profil,
      'label': label.map((e) => {'id': e.id, 'nama': e.nama}).toList(),
      'transaksi': transaksi
          .map(
            (e) => {
              'id': e.id,
              'tipe': e.tipe.name,
              'nominal': e.nominal,
              'biayaTambahan': e.biayaTambahan,
              'kuantitas': e.kuantitas,
              'akunSumberId': e.akunSumberId,
              'akunTujuanId': e.akunTujuanId,
              'labelId': e.labelId,
              'waktu': e.waktu.toIso8601String(),
              'catatan': e.catatan,
            },
          )
          .toList(),
      'utang_piutang': utang
          .map(
            (e) => {
              'id': e.id,
              'tipe': e.tipe.name,
              'nominal': e.nominal,
              'pihakTerkait': e.pihakTerkait,
              'akunId': e.akunId,
              'waktu': e.waktu.toIso8601String(),
              'tenggatWaktu': e.tenggatWaktu.toIso8601String(),
              'catatan': e.catatan,
              'isLunas': e.isLunas ? 1 : 0,
            },
          )
          .toList(),
    };

    final rawJson = jsonEncode(seluruhData);
    final key = enc.Key.fromUtf8(password.padRight(32, '0').substring(0, 32));
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));

    final encrypted = encrypter.encrypt(rawJson, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  // Memproses string terenkripsi dan memasukkannya ke database
  Future<void> restoreFromEncryptedString(
    String content,
    String password,
  ) async {
    final parts = content.split(':');
    if (parts.length != 2) throw Exception('Format file tidak valid.');

    final iv = enc.IV.fromBase64(parts[0]);
    final encrypted = enc.Encrypted.fromBase64(parts[1]);
    final key = enc.Key.fromUtf8(password.padRight(32, '0').substring(0, 32));
    final encrypter = enc.Encrypter(enc.AES(key));

    final decryptedJson = encrypter.decrypt(encrypted, iv: iv);
    final Map<String, dynamic> data = jsonDecode(decryptedJson);

    await _dbRepo.resetDatabase();
    if (data['profil'] != null) {
      await _dbRepo.saveProfil(
        data['profil']['nama'],
        data['profil']['fotoBase64'],
      );
    }
    if (data['akun'] != null) {
      for (var item in data['akun']) {
        await _dbRepo.insertAkun(AkunModel(id: item['id'], nama: item['nama']));
      }
    }
    if (data['label'] != null) {
      for (var item in data['label']) {
        await _dbRepo.insertLabel(
          LabelModel(id: item['id'], nama: item['nama']),
        );
      }
    }
    if (data['transaksi'] != null) {
      for (var item in data['transaksi']) {
        await _dbRepo.insertTransaksi(
          TransaksiModel(
            id: item['id'],
            tipe: TipeTransaksi.values.firstWhere(
              (e) => e.name == item['tipe'],
            ),
            nominal: (item['nominal'] as num).toDouble(),
            biayaTambahan: item['biayaTambahan'] != null
                ? (item['biayaTambahan'] as num).toDouble()
                : null,
            kuantitas: item['kuantitas'],
            akunSumberId: item['akunSumberId'],
            akunTujuanId: item['akunTujuanId'],
            labelId: item['labelId'],
            waktu: DateTime.parse(item['waktu']),
            catatan: item['catatan'],
          ),
        );
      }
    }
    if (data['utang_piutang'] != null) {
      for (var item in data['utang_piutang']) {
        await _dbRepo.insertUtangPiutang(
          UtangPiutangModel(
            id: item['id'],
            tipe: TipeUtangPiutang.values.firstWhere(
              (e) => e.name == item['tipe'],
            ),
            nominal: (item['nominal'] as num).toDouble(),
            pihakTerkait: item['pihakTerkait'],
            akunId: item['akunId'],
            waktu: DateTime.parse(item['waktu']),
            tenggatWaktu: DateTime.parse(item['tenggatWaktu']),
            catatan: item['catatan'],
            isLunas: item['isLunas'] == 1,
          ),
        );
      }
    }
  }
}
