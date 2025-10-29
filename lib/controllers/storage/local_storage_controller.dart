import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _currentGrIdKey = 'current_gr_id';
  static const String _grSequenceKey = 'gr_sequence_';

  Future<void> setCurrentGrId(String grId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentGrIdKey, grId);
  }

  Future<String?> getCurrentGrId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentGrIdKey);
  }

  Future<void> clearCurrentGrId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentGrIdKey);
  }

  Future<int> getGrSequence(String year) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_grSequenceKey$year') ?? 0;
  }

  Future<void> saveGrSequence(String year, int sequence) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_grSequenceKey$year', sequence);
  }

  // TAMBAHKAN METHOD INI
  Future<void> markGrIdAsUsed(String grId) async {
    final prefs = await SharedPreferences.getInstance();
    final usedGrIds = prefs.getStringList('used_gr_ids') ?? [];
    if (!usedGrIds.contains(grId)) {
      usedGrIds.add(grId);
      await prefs.setStringList('used_gr_ids', usedGrIds);
    }
  }

  // TAMBAHKAN METHOD INI JUGA (untuk mengecek apakah GR ID sudah digunakan)
  Future<bool> isGrIdUsed(String grId) async {
    final prefs = await SharedPreferences.getInstance();
    final usedGrIds = prefs.getStringList('used_gr_ids') ?? [];
    return usedGrIds.contains(grId);
  }

  // Optional: Method untuk membersihkan GR ID yang sudah digunakan (jika diperlukan)
  Future<void> clearUsedGrIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('used_gr_ids');
  }
}
