import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transaksi_controller.dart';
import 'utang_piutang_controller.dart';
import '../models/transaksi_model.dart';
import '../models/utang_piutang_model.dart';

class SummaryData {
  final double totalPemasukan;
  final double totalPengeluaran;

  SummaryData(this.totalPemasukan, this.totalPengeluaran);
}

final summaryProvider = Provider<SummaryData>((ref) {
  final transaksiState = ref.watch(transaksiControllerProvider);
  final utangState = ref.watch(utangPiutangControllerProvider);

  double totalPemasukan = 0;
  double totalPengeluaran = 0;

  // 1. Kalkulasi pencairan awal Utang dan Piutang
  if (utangState is AsyncData && utangState.value != null) {
    for (var u in utangState.value!) {
      if (u.tipe == TipeUtangPiutang.utang) {
        // Pembuatan utang dihitung sebagai uang masuk
        totalPemasukan += u.nominal;
      } else if (u.tipe == TipeUtangPiutang.piutang) {
        // Pembuatan piutang dihitung sebagai uang keluar
        totalPengeluaran += u.nominal;
      }
    }
  }

  // 2. Kalkulasi berdasarkan log transaksi (termasuk log pelunasan)
  if (transaksiState is AsyncData && transaksiState.value != null) {
    for (var t in transaksiState.value!) {
      final nominal = t.nominal * t.kuantitas;
      final biaya = t.biayaTambahan ?? 0;

      if (t.tipe == TipeTransaksi.pemasukan) {
        totalPemasukan += nominal;
      } else if (t.tipe == TipeTransaksi.pengeluaran) {
        totalPengeluaran += (nominal + biaya);
      } else if (t.tipe == TipeTransaksi.transfer) {
        totalPengeluaran += biaya; // Transfer hanya menghitung biaya tambahan sebagai pengeluaran
      }
    }
  }

  return SummaryData(totalPemasukan, totalPengeluaran);
});
