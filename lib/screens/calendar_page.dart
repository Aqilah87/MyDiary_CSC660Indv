import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '/pages/entry_form_page.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return List.generate(lastDay.day, (i) => DateTime(month.year, month.month, i + 1));
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
      // You can pass the selectedDate into EntryFormPage if you want
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Diary added for ${DateFormat.yMMMd().format(selectedDate)}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth(_focusedMonth);
    final monthName = DateFormat.yMMMM().format(_focusedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text('Diary Calendar'),
        backgroundColor: const Color.fromARGB(255, 30, 160, 216),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _goToPreviousMonth, icon: Icon(Icons.chevron_left)),
                Text(monthName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  .map((d) => Expanded(
                        child: Center(
                            child: Text(d,
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ))
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
                  return Container(); // empty for spacing
                }
                final actualIndex = index - (daysInMonth.first.weekday - 1);
                final day = daysInMonth[actualIndex];

                return Container(
                  margin: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('${day.day}', style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: Colors.blue),
                        onPressed: () => _createEntry(day),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}