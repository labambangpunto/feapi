import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/utang_piutang_model.dart';
import '../repositories/database_repository.dart';

final utangPiutangControllerProvider =
    StateNotifierProvider<
      UtangPiutangController,
      AsyncValue<List<UtangPiutangModel>>
    >((ref) {
      final repository = ref.watch(databaseRepositoryProvider);
      return UtangPiutangController(repository);
    });

class UtangPiutangController
    extends StateNotifier<AsyncValue<List<UtangPiutangModel>>> {
  final DatabaseRepository _repository;

  UtangPiutangController(this._repository) : super(const AsyncValue.loading()) {
    fetchUtangPiutang();
  }

  Future<void> fetchUtangPiutang() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getSemuaUtangPiutang();
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> tambahUtangPiutang(UtangPiutangModel data) async {
    await _repository.insertUtangPiutang(data);
    await fetchUtangPiutang();
  }

  Future<void> hapusUtangPiutang(String id) async {
    await _repository.deleteUtangPiutang(id);
    await fetchUtangPiutang();
  }

  Future<void> updateUtangPiutang(UtangPiutangModel data) async {
    await _repository.updateUtangPiutang(data);
    await fetchUtangPiutang();
  }
}
