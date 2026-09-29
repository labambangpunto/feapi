import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'akun_controller.dart';
import 'transaksi_controller.dart';
import 'utang_piutang_controller.dart';
import '../models/transaksi_model.dart';
import '../models/utang_piutang_model.dart';

class SummaryData {
  final double totalSaldo;
  final double totalPemasukan;
  final double totalPengeluaran;
  final Map<String, double> saldoPerAkun;

  SummaryData(
    this.totalSaldo,
    this.totalPemasukan,
    this.totalPengeluaran,
    this.saldoPerAkun,
  );
}

final summaryProvider = Provider<SummaryData>((ref) {
  final akunState = ref.watch(akunControllerProvider);
  final transaksiState = ref.watch(transaksiControllerProvider);
  final utangState = ref.watch(utangPiutangControllerProvider);

  double totalPemasukan = 0;
  double totalPengeluaran = 0;
  Map<String, double> saldoPerAkun = {};

  // 1. Masukkan saldo awal masing-masing akun
  if (akunState is AsyncData && akunState.value != null) {
    for (var akun in akunState.value!) {
      saldoPerAkun[akun.id] = akun.saldoAwal;
    }
  }

  // 2. Kalkulasi pencairan awal Utang dan Piutang
  if (utangState is AsyncData && utangState.value != null) {
    for (var u in utangState.value!) {
      if (u.tipe == TipeUtangPiutang.utang) {
        // Pembuatan utang dihitung sebagai uang masuk
        totalPemasukan += u.nominal;
        if (u.akunId != null && saldoPerAkun.containsKey(u.akunId)) {
          saldoPerAkun[u.akunId!] = saldoPerAkun[u.akunId!]! + u.nominal;
        }
      } else if (u.tipe == TipeUtangPiutang.piutang) {
        // Pembuatan piutang dihitung sebagai uang keluar
        totalPengeluaran += u.nominal;
        if (u.akunId != null && saldoPerAkun.containsKey(u.akunId)) {
          saldoPerAkun[u.akunId!] = saldoPerAkun[u.akunId!]! - u.nominal;
        }
      }
    }
  }

  // 3. Kalkulasi berdasarkan log transaksi (termasuk log pelunasan)
  if (transaksiState is AsyncData && transaksiState.value != null) {
    for (var t in transaksiState.value!) {
      final nominal = t.nominal * t.kuantitas;
      final biaya = t.biayaTambahan ?? 0;

      if (t.tipe == TipeTransaksi.pemasukan) {
        totalPemasukan += nominal;
        if (t.akunTujuanId != null &&
            saldoPerAkun.containsKey(t.akunTujuanId)) {
          saldoPerAkun[t.akunTujuanId!] =
              saldoPerAkun[t.akunTujuanId!]! + nominal;
        }
      } else if (t.tipe == TipeTransaksi.pengeluaran) {
        totalPengeluaran += (nominal + biaya);
        if (t.akunSumberId != null &&
            saldoPerAkun.containsKey(t.akunSumberId)) {
          saldoPerAkun[t.akunSumberId!] =
              saldoPerAkun[t.akunSumberId!]! - (nominal + biaya);
        }
      } else if (t.tipe == TipeTransaksi.transfer) {
        totalPengeluaran += biaya;
        if (t.akunSumberId != null &&
            saldoPerAkun.containsKey(t.akunSumberId)) {
          saldoPerAkun[t.akunSumberId!] =
              saldoPerAkun[t.akunSumberId!]! - nominal - biaya;
        }
        if (t.akunTujuanId != null &&
            saldoPerAkun.containsKey(t.akunTujuanId)) {
          saldoPerAkun[t.akunTujuanId!] =
              saldoPerAkun[t.akunTujuanId!]! + nominal;
        }
      }
    }
  }

  // 4. Kalkulasi total saldo dari seluruh akun
  double totalSaldo = saldoPerAkun.values.fold(0, (sum, item) => sum + item);

  return SummaryData(
    totalSaldo,
    totalPemasukan,
    totalPengeluaran,
    saldoPerAkun,
  );
});
