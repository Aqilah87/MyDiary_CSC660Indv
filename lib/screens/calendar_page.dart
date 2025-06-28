import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '/pages/entry_form_page.dart';
import 'package:collection/collection.dart';

class CalendarPage extends StatefulWidget {
  final List<DiaryEntry> entries;
  CalendarPage({required this.entries});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return List.generate(
      lastDay.day,
      (i) => DateTime(month.year, month.month, i + 1),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _createEntry(DateTime selectedDate) async {
    final newEntry = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EntryFormPage()),
    );
    if (newEntry != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Diary added for ${DateFormat.yMMMd().format(selectedDate)}"),
        ),
      );
      setState(() {}); // refresh UI if needed
    }
  }

  DiaryEntry? _getEntryForDate(DateTime date) {
    return widget.entries.firstWhereOrNull(
      (e) =>
      e.date.year == date.year &&
      e.date.month == date.month &&
      e.date.day == date.day,
    );
  }

  List<DiaryEntry> _getEntriesForSelectedDate() {
    if (_selectedDate == null) return [];
    return widget.entries.where(
      (e) =>
      e.date.year == _selectedDate!.year &&
      e.date.month == _selectedDate!.month &&
      e.date.day == _selectedDate!.day
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth(_focusedMonth);
    final monthName = DateFormat.yMMMM().format(_focusedMonth);
    final selectedEntries = _getEntriesForSelectedDate();

    return Scaffold(
      appBar: AppBar(
        title: Text('Diary Calendar'),
        backgroundColor: const Color.fromARGB(255, 115, 204, 241),
        centerTitle: true,
      ),
      backgroundColor: const Color.fromARGB(255, 207, 238, 251),

      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _goToPreviousMonth, icon: Icon(Icons.chevron_left)),
                Text(
                  monthName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: _goToNextMonth, icon: Icon(Icons.chevron_right)),
              ],
            ),
          ),
          

          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Calendar grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),

              itemCount: daysInMonth.length + daysInMonth.first.weekday - 1,
              itemBuilder: (context, index) {
                if (index < daysInMonth.first.weekday - 1) {
                  return SizedBox(); // empty space for alignment
                }

                final actualIndex = index - (daysInMonth.first.weekday - 1);
                final day = daysInMonth[actualIndex];
                final entry = _getEntryForDate(day);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = day; // ✅ Set selected date
                    });
                    if (entry == null) {
                      _createEntry(day);
                    } 
                  },
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: entry != null 
                            ? Colors.black87 
                            : Colors.black54,
                          ),
                        ),
                        SizedBox(height: 4),
                        entry == null
                            ? Icon(Icons.add_circle_outline,
                            size: 20, color: Color.fromARGB(255, 137, 87, 0),)
                            : Text(entry.emoji,
                            style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 📥 Diary entries below calendar
          if (_selectedDate != null && selectedEntries.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  Text(
                    'Entries for ${DateFormat.yMMMMd().format(_selectedDate!)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  ...selectedEntries.map(
                    (entry) => Card(
                      child: ListTile(
                        leading: Text(entry.emoji,
                            style: TextStyle(fontSize: 22)),
                        title: Text(entry.title),
                        subtitle: Text(entry.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}