import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pembukuan_model.dart';
import '../repositories/database_repository.dart';

final pembukuanControllerProvider =
    StateNotifierProvider<
      PembukuanController,
      AsyncValue<List<PembukuanModel>>
    >((ref) {
      final repository = ref.watch(databaseRepositoryProvider);
      return PembukuanController(repository);
    });

class PembukuanController
    extends StateNotifier<AsyncValue<List<PembukuanModel>>> {
  final DatabaseRepository _repository;

  PembukuanController(this._repository) : super(const AsyncValue.loading()) {
    fetchPembukuan();
  }

  Future<void> fetchPembukuan() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getSemuaPembukuan();
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> tambahPembukuan(PembukuanModel data) async {
    await _repository.insertPembukuan(data);
    await fetchPembukuan();
  }

  Future<void> updatePembukuan(PembukuanModel data) async {
    await _repository.updatePembukuan(data);
    await fetchPembukuan();
  }
}
