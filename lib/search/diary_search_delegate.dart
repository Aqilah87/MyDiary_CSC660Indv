import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart'; // adjust this if your model file has a different name

class DiarySearchDelegate extends SearchDelegate<String> {
  final List<DiaryEntry> entries;

  DiarySearchDelegate(this.entries);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = entries.where((entry) {
      return entry.title.toLowerCase().contains(query.toLowerCase()) ||
          entry.text.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final result = suggestions[index];
        return ListTile(
          leading: Text(result.emoji, style: const TextStyle(fontSize: 28)),
          title: Text(result.title),
          subtitle: Text(
            DateFormat.yMMMd().add_jm().format(result.date),
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () => close(context, result.title),
        );
      },
    );
  }
}