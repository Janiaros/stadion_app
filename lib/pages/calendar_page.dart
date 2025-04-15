// lib/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';
import 'appointment_detail_page.dart';
import 'appointment_form_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool _loading = true;
  List<Appointment> _allAppointments = [];
  List<Appointment> _displayedAppointments = [];
  DateTime selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      List<Appointment> fetched = await ApiService.fetchAppointments();
      // Sortiere alle Termine nach Datum
      fetched.sort((a, b) => a.date.compareTo(b.date));
      setState(() {
        _allAppointments = fetched;
        _loading = false;
      });
      _filterAppointments();
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler beim Laden der Termine: $e')));
    }
  }

  /// Filtert die Termine basierend auf dem ausgewählten Monat.
  void _filterAppointments() {
    setState(() {
      _displayedAppointments = _allAppointments.where((appointment) {
        return appointment.date.year == selectedMonth.year &&
            appointment.date.month == selectedMonth.month;
      }).toList();
    });
  }

  /// Verschiebt den aktuellen Anzeigemonat um delta Monate.
  void _changeMonth(int delta) {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + delta);
    });
    _filterAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kalender")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Monatsnavigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat("MMMM yyyy", "de_DE").format(selectedMonth),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _displayedAppointments.isNotEmpty
                ? ListView.builder(
              itemCount: _displayedAppointments.length,
              itemBuilder: (context, index) {
                Appointment appt = _displayedAppointments[index];
                return ListTile(
                  title: Text(appt.title),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(appt.date)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetailPage(appointment: appt),
                      ),
                    );
                  },
                );
              },
            )
                : const Center(child: Text("Keine Termine in diesem Monat")),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final newAppointment = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentFormPage(),
            ),
          );
          if (newAppointment != null) {
            _loadAppointments();
          }
        },
      ),
    );
  }
}
