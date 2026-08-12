import 'package:flutter/foundation.dart';

import '../../../../shared/models/ui_models.dart';
import '../../data/watchlist_repository.dart';

class WatchlistController extends ChangeNotifier {
  WatchlistController({required WatchlistRepository watchlistRepository})
    : _watchlistRepository = watchlistRepository;

  final WatchlistRepository _watchlistRepository;

  List<WatchlistViewData> _items = [];
  bool _isLoading = false;
  String? _error;

  List<WatchlistViewData> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _watchlistRepository.getWatchlist(userId);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateThreshold({
    required int userId,
    required int watchlistId,
    double? threshold,
  }) async {
    await _watchlistRepository.updateThreshold(
      watchlistId: watchlistId,
      threshold: threshold,
    );
    await load(userId);
  }

  Future<void> remove({required int userId, required int watchlistId}) async {
    await _watchlistRepository.removeWatchlist(watchlistId);
    await load(userId);
  }
}
