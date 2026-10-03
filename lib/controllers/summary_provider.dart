import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transaksi_controller.dart';
import '../models/transaksi_model.dart';

class SummaryData {
  final double totalPemasukan;
  final double totalPengeluaran;

  SummaryData(this.totalPemasukan, this.totalPengeluaran);
}

final summaryProvider = Provider<SummaryData>((ref) {
  final transaksiState = ref.watch(transaksiControllerProvider);

  double totalPemasukan = 0;
  double totalPengeluaran = 0;

  // Kalkulasi murni berdasarkan log transaksi (pembuatan utang/piutang dan pelunasan kini sudah tercatat otomatis di sini)
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
