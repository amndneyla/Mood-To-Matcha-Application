import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/db_service.dart';
import '../models/journal_model.dart';
import '../utils/constants.dart';
import '../utils/global_time.dart'; // ✅ untuk konversi zona waktu

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _db = DBService.instance;
  final _controller = TextEditingController();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<JournalEntry> _journals = [];

  String _selectedZone = 'WIB';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadJournalsByDay(_selectedDay);
  }

  Future<void> _loadJournalsByDay(DateTime day) async {
    final result = await _db.getJournalsByDate(day);
    setState(() => _journals = result);
  }

  Future<void> _saveJournal() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _saving = true);

    final entry = JournalEntry(
      title: 'Mood ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
      note: _controller.text.trim(),
      createdAt: TimeUtils.nowWithZone(_selectedZone), // ✅ konversi zona waktu
    );

    await _db.addJournal(entry);
    _controller.clear();

    await _loadJournalsByDay(_selectedDay);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jurnal berhasil disimpan 📔')),
      );
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: Text(
          'Mood Journal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 📅 Kalender
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _loadJournalsByDay(selected);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 🌍 Zona waktu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Zona waktu:', style: GoogleFonts.poppins(fontSize: 14)),
              DropdownButton<String>(
                value: _selectedZone,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'WIB', child: Text('WIB')),
                  DropdownMenuItem(value: 'WITA', child: Text('WITA')),
                  DropdownMenuItem(value: 'WIT', child: Text('WIT')),
                  DropdownMenuItem(value: 'London', child: Text('London')),
                ],
                onChanged: (v) => setState(() => _selectedZone = v!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Waktu sekarang (${_selectedZone}): '
            '${DateFormat('HH:mm').format(DateTime.parse(TimeUtils.nowWithZone(_selectedZone)))}',
            style: GoogleFonts.poppins(fontSize: 12, color: kSubtitleColor),
          ),
          const SizedBox(height: 16),

          // ✍️ Input jurnal
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tulis mood kamu hari ini 🍵',
              fillColor: Colors.green.shade50,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: _saving ? null : _saveJournal,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size.fromHeight(45),
            ),
            child: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Simpan Jurnal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          // 🧾 Daftar jurnal
          Text(
            'Catatan Hari Ini (${DateFormat('dd MMM yyyy').format(_selectedDay)})',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 10),

          if (_journals.isEmpty)
            Center(
              child: Text(
                'Belum ada catatan.',
                style: GoogleFonts.poppins(color: kSubtitleColor),
              ),
            )
          else
            ..._journals.map(
              (j) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                child: ListTile(
                  title: Text(
                    j.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      j.note,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        TimeUtils.formatWithZone(
                          DateTime.parse(j.createdAt),
                          _selectedZone,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: kSubtitleColor,
                        ),
                      ),
                      Text(
                        _selectedZone,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
