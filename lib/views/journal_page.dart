import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/db_service.dart';
import '../models/journal_model.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({Key? key}) : super(key: key);

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  String _selectedZone = 'WIB';
  String _displayTime = '';
  final TextEditingController _noteController = TextEditingController();

  List<JournalEntry> _journals = [];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _loadJournals();
  }

  void _updateTime() {
    DateTime now = DateTime.now();
    switch (_selectedZone) {
      case 'WITA':
        now = now.add(const Duration(hours: 1));
        break;
      case 'WIT':
        now = now.add(const Duration(hours: 2));
        break;
      case 'London':
        now = now.subtract(const Duration(hours: 7));
        break;
    }
    final formattedTime = DateFormat('HH:mm').format(now);
    setState(() {
      _displayTime = 'Waktu sekarang (${_selectedZone}): $formattedTime';
    });
  }

  Future<void> _loadJournals() async {
    final list = await DBService.instance.getJournalsByDate(_selectedDay);
    setState(() => _journals = list);
  }

  Future<void> _saveJournal() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis mood kamu dulu ya 🌿')),
      );
      return;
    }

    final localNow = DateTime.now();
    final selectedDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      localNow.hour,
      localNow.minute,
      localNow.second,
    );

    final currentUser = await DBService.instance.getLoggedInUser();
    final entry = JournalEntry(
      title: 'Mood ${DateFormat('dd MMM yyyy').format(selectedDate)}',
      note: _noteController.text.trim(),
      createdAt: selectedDate.toUtc().toIso8601String(),
      createdLocal: selectedDate.toIso8601String(),
      zone: _selectedZone,
      userId: currentUser?['user_id'],
    );

    unawaited(DBService.instance.addJournal(entry));
    unawaited(DBService.instance.addPoints(10));

    _noteController.clear();
    await _loadJournals();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Jurnal tanggal ${DateFormat('dd MMM yyyy').format(selectedDate)} berhasil disimpan!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Journal'),
        backgroundColor: const Color.fromARGB(255, 73, 128, 76),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2023),
              lastDay: DateTime(2030),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) async {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
                await _loadJournals();
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.green.shade700,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Zona waktu:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedZone,
                    items: const [
                      DropdownMenuItem(value: 'WIB', child: Text('WIB')),
                      DropdownMenuItem(value: 'WITA', child: Text('WITA')),
                      DropdownMenuItem(value: 'WIT', child: Text('WIT')),
                      DropdownMenuItem(value: 'London', child: Text('London')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedZone = v);
                      _updateTime();
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(_displayTime),

                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Tulis mood kamu hari ini 😊',
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Jurnal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveJournal,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_journals.isNotEmpty)
                    Text(
                      'Catatan Hari Ini (${DateFormat('dd MMM yyyy').format(_selectedDay)})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                  const SizedBox(height: 8),

                  ..._journals.map((j) {
                    final localTime = DateFormat(
                      'HH:mm',
                    ).format(DateTime.parse(j.createdLocal));

                    return Card(
                      elevation: 2,
                      color: Colors.green.shade50,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    j.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(j.note),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  j.zone,
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  localTime,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        backgroundColor: Colors.white,
                                        title: const Text(
                                          'Hapus Catatan',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: const Text(
                                          'Yakin mau hapus catatan ini?',
                                        ),
                                        actionsAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        actions: [
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: Colors.green.shade700,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              'Batal',
                                              style: TextStyle(
                                                color: Colors.green.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green.shade700,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                    vertical: 10,
                                                  ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Hapus',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await DBService.instance.deleteJournal(
                                        j.id!,
                                      );
                                      await _loadJournals();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '🗑️ Catatan berhasil dihapus',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
