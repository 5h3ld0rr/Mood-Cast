import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _key = 'search_history';

  /// Adds a new search term to the history. Keeps most recent at the front.
  Future<void> addSearch(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    // Remove if already exists to avoid duplicates, then add to front.
    history.remove(term);
    history.insert(0, term);
    // Keep only latest 50 entries.
    if (history.length > 50) history.removeRange(50, history.length);
    await prefs.setStringList(_key, history);
  }

  /// Retrieves the full search history (most recent first).
  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// Clears all saved search history.
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Deletes a specific term from the history.
  Future<void> deleteTerm(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    history.remove(term);
    await prefs.setStringList(_key, history);
  }
}
