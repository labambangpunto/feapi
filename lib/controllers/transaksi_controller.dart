import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaksi_model.dart';
import '../repositories/database_repository.dart';

final transaksiControllerProvider =
    StateNotifierProvider<
      TransaksiController,
      AsyncValue<List<TransaksiModel>>
    >((ref) {
      final repository = ref.watch(databaseRepositoryProvider);
      return TransaksiController(repository);
    });

class TransaksiController
    extends StateNotifier<AsyncValue<List<TransaksiModel>>> {
  final DatabaseRepository _repository;

  TransaksiController(this._repository) : super(const AsyncValue.loading()) {
    fetchTransaksi();
  }

  Future<void> fetchTransaksi() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getSemuaTransaksi();
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> tambahTransaksi(TransaksiModel transaksi) async {
    await _repository.insertTransaksi(transaksi);
    await fetchTransaksi();
  }

  Future<void> hapusTransaksi(String id) async {
    await _repository.deleteTransaksi(id);
    await fetchTransaksi();
  }

  Future<void> updateTransaksi(TransaksiModel transaksi) async {
    await _repository.updateTransaksi(transaksi);
    await fetchTransaksi();
  }
}
