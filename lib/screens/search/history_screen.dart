import 'package:flutter/material.dart';
import '../../services/search_history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SearchHistoryService _historyService = SearchHistoryService();
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await _historyService.getHistory();
    setState(() => _history = h);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Search History',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _history.isEmpty
          ? const Center(
              child: Text(
                'No recent searches',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.separated(
              itemCount: _history.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, index) {
                final term = _history[index];
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.white70),
                  title: Text(
                    term,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: () async {
                      await _historyService.deleteTerm(term);
                      _loadHistory(); // Refresh the list
                    },
                  ),
                  onTap: () => Navigator.pop(context, term),
                );
              },
            ),
    );
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Search History'),
        content: const Text(
          'Are you sure you want to delete all search history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _clearHistory();
    }
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    setState(() => _history = []);
  }
}
