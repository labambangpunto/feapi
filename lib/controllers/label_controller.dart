import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/label_model.dart';
import '../repositories/database_repository.dart';

final labelControllerProvider =
    StateNotifierProvider<LabelController, AsyncValue<List<LabelModel>>>((ref) {
      final repository = ref.watch(databaseRepositoryProvider);
      return LabelController(repository);
    });

class LabelController extends StateNotifier<AsyncValue<List<LabelModel>>> {
  final DatabaseRepository _repository;

  LabelController(this._repository) : super(const AsyncValue.loading()) {
    fetchLabel();
  }

  Future<void> fetchLabel() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getSemuaLabel();
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> tambahLabel(LabelModel label) async {
    await _repository.insertLabel(label);
    await fetchLabel();
  }

  Future<void> updateLabel(LabelModel label) async {
    await _repository.updateLabel(label);
    await fetchLabel(); // Refresh state menggunakan fungsi yang sudah ada
  }

  Future<void> hapusLabel(String id) async {
    await _repository.deleteLabel(id);
    await fetchLabel();
  }
}
