import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/akun_model.dart';
import '../repositories/database_repository.dart';

final akunControllerProvider =
    StateNotifierProvider<AkunController, AsyncValue<List<AkunModel>>>((ref) {
      final repository = ref.watch(databaseRepositoryProvider);
      return AkunController(repository);
    });

class AkunController extends StateNotifier<AsyncValue<List<AkunModel>>> {
  final DatabaseRepository _repository;

  AkunController(this._repository) : super(const AsyncValue.loading()) {
    fetchAkun();
  }

  Future<void> fetchAkun() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getSemuaAkun();
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> tambahAkun(AkunModel akun) async {
    await _repository.insertAkun(akun);
    await fetchAkun(); // Refresh state setelah insert
  }

  Future<void> hapusAkun(String id) async {
    await _repository.deleteAkun(id);
    await fetchAkun(); // Refresh state setelah delete
  }
}
