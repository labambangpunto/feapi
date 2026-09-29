import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'akun_controller.dart';
import 'transaksi_controller.dart';
import '../models/transaksi_model.dart';

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

  double totalPemasukan = 0;
  double totalPengeluaran = 0;
  Map<String, double> saldoPerAkun = {};

  // 1. Masukkan saldo awal masing-masing akun
  if (akunState is AsyncData && akunState.value != null) {
    for (var akun in akunState.value!) {
      saldoPerAkun[akun.id] = akun.saldoAwal;
    }
  }

  // 2. Kalkulasi berdasarkan log transaksi
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
        totalPengeluaran +=
            biaya; // Biaya tambahan otomatis dianggap pengeluaran
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

  // 3. Kalkulasi total saldo dari seluruh akun
  double totalSaldo = saldoPerAkun.values.fold(0, (sum, item) => sum + item);

  return SummaryData(
    totalSaldo,
    totalPemasukan,
    totalPengeluaran,
    saldoPerAkun,
  );
});
