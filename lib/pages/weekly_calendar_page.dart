// lib/pages/weekly_calendar_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'shift_form_page.dart';

class WeeklyCalendarPage extends StatefulWidget {
  const WeeklyCalendarPage({super.key});
  @override
  _WeeklyCalendarPageState createState() => _WeeklyCalendarPageState();
}

class _WeeklyCalendarPageState extends State<WeeklyCalendarPage> {
  int weekOffset = 0;
  List<Shift> shifts = []; // Alle Schichten aus der DB (shift.date als "yyyy-MM-dd")
  List<Employee> activeEmployees = []; // Alle Mitarbeiter
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadShifts();
    _loadActiveEmployees();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt("userId");
    });
  }

  Future<void> _loadShifts() async {
    try {
      List<Shift> fetched = await ApiService.fetchShifts();
      print("Geladene Schichten: ${fetched.length}");
      setState(() {
        shifts = fetched;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Schichten: $e')));
    }
  }

  Future<void> _loadActiveEmployees() async {
    try {
      List<Employee> fetched = await ApiService.fetchEmployees();
      print("Geladene Mitarbeiter: ${fetched.length}");
      setState(() {
        activeEmployees = fetched;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Mitarbeiter: $e')));
    }
  }

  /// Erzeugt eine Liste von DateTime-Objekten, die den Tagen der aktuellen Woche entsprechen.
  List<DateTime> getWeekDays() {
    final now = DateTime.now();
    // Erstelle ein Datum ohne Uhrzeit (nur Jahr, Monat, Tag)
    final today = DateTime(now.year, now.month, now.day);
    // Berechne den Montag der Woche, angepasst um weekOffset Wochen
    final monday = today.subtract(Duration(days: today.weekday - 1))
        .add(Duration(days: weekOffset * 7));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  /// Formatiert ein DateTime in einen String "yyyy-MM-dd".
  String _formatDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Formatiert ein DateTime in das Display-Format "Wochentag - TT.MM.yyyy".
  String _formatDisplayDate(DateTime date) {
    final weekday = DateFormat.E('de_DE').format(date).replaceAll('.', '');
    final formatted = DateFormat('dd.MM.yyyy', 'de_DE').format(date);
    return '$weekday - $formatted';
  }

  /// Kürzt einen Zeit-String "HH:MM:SS" zu "HH:MM".
  String _displayTime(String timeStr) {
    if (timeStr.length >= 5) {
      return timeStr.substring(0, 5);
    }
    return timeStr;
  }

  /// Dialog zum Zuweisen von Mitarbeitern an eine Schicht.
  void _showAddEmployeeDialog(Shift shift) {
    final selectedEmployees = {...shift.assignedEmployees};
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Mitarbeiter zuweisen"),
              content: SingleChildScrollView(
                child: Column(
                  children: activeEmployees.map((emp) {
                    final isSelected = selectedEmployees.contains(emp);
                    return CheckboxListTile(
                      title: Text(emp.name),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            selectedEmployees.add(emp);
                          } else {
                            selectedEmployees.remove(emp);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Abbrechen"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      shift.assignedEmployees = selectedEmployees.toList();
                    });
                    Navigator.pop(context);
                    final assignedIds = shift.assignedEmployees.map((e) => e.id).toList();
                    print("Debug: Zuweisung, Mitarbeiter-IDs: $assignedIds");
                    // Hier wird shift.date als unveränderter String (z.B. "yyyy-MM-dd") an die API übergeben.
                    final result = await ApiService.updateShift(
                      shiftId: shift.id,
                      shiftDate: shift.date,
                      startTime: shift.startTime,
                      endTime: shift.endTime,
                      description: shift.description,
                      assignedEmployeeIds: assignedIds,
                    );
                    print("Debug: Update Shift result: $result");
                    await _loadShifts();
                  },
                  child: const Text("Speichern"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Löscht einen Shift nach Bestätigung.
  Future<void> _deleteShift(Shift shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bestätigung"),
        content: const Text("Möchten Sie diese Schicht wirklich löschen?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Löschen"),
          ),
        ],
      ),
    ) ??
        false;
    if (confirmed) {
      await ApiService.deleteShift(shiftId: shift.id);
      await _loadShifts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = getWeekDays();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wochenkalender - Schichtverwaltung"),
      ),
      body: Column(
        children: [
          // Header mit Navigationspfeilen und Anzeige der Woche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () => setState(() => weekOffset--),
                ),
                Text(
                  "${_formatDisplayDate(weekDays.first)} - ${_formatDisplayDate(weekDays.last)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () => setState(() => weekOffset++),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: weekDays.length,
              itemBuilder: (context, index) {
                final day = weekDays[index];
                final dayString = _formatDateString(day);
                // Filtere alle Schichten, deren shift.date exakt diesem Tag entspricht.
                final shiftsForDay = shifts.where((shift) => shift.date == dayString).toList();

                // Sortiere die Schichten nach Startzeit (aufsteigend)
                shiftsForDay.sort((a, b) {
                  final partsA = a.startTime.split(':').map(int.parse).toList();
                  final partsB = b.startTime.split(':').map(int.parse).toList();
                  final durA = Duration(hours: partsA[0], minutes: partsA[1], seconds: partsA[2]);
                  final durB = Duration(hours: partsB[0], minutes: partsB[1], seconds: partsB[2]);
                  return durA.compareTo(durB);
                });

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kopfzeile mit Tagesinformation und Button "Neue Schicht"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${DateFormat.E('de_DE').format(day).replaceAll('.', '')} - ${DateFormat('dd.MM.yyyy', 'de_DE').format(day)}",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final newShift = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShiftFormPage(initialDate: dayString),
                                  ),
                                );
                                if (newShift != null) {
                                  await _loadShifts();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text("+ Schicht"),
                            ),
                          ],
                        ),
                        const Divider(),
                        // Anzeige der Schichten für diesen Tag
                        shiftsForDay.isNotEmpty
                            ? Column(
                          children: shiftsForDay.map((shift) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Zeile: Start-/Endzeit (ohne Sekunden) und Beschreibung
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${_displayTime(shift.startTime)} - ${_displayTime(shift.endTime)}",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(shift.description),
                                        ],
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == "edit") {
                                            final updatedShift = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ShiftFormPage(initialShift: shift),
                                              ),
                                            );
                                            if (updatedShift != null) {
                                              await _loadShifts();
                                            }
                                          } else if (value == "delete") {
                                            await _deleteShift(shift);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: "edit",
                                            child: Text("Bearbeiten"),
                                          ),
                                          PopupMenuItem(
                                            value: "delete",
                                            child: Text("Löschen"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Anzeige der zugewiesenen Mitarbeiter.
                                  // Falls ein zugewiesener Mitarbeiter der aktuell eingeloggte Nutzer ist,
                                  // wird sein Chip mit einer speziellen Farbe hervorgehoben.
                                  shift.assignedEmployees.isNotEmpty
                                      ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Zugewiesen:", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Wrap(
                                        spacing: 6,
                                        children: shift.assignedEmployees.map((emp) {
                                          final bool isCurrentUser = (currentUserId != null && emp.id == currentUserId);
                                          return Chip(
                                            label: Text(emp.name),
                                            backgroundColor: isCurrentUser ? Colors.blueAccent : null,
                                            labelStyle: isCurrentUser ? const TextStyle(color: Colors.white) : null,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  )
                                      : const Text("Keine Mitarbeiter zugewiesen."),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.person_add),
                                        onPressed: () {
                                          _showAddEmployeeDialog(shift);
                                        },
                                      ),
                                      const Text("Mitarbeiter zuweisen"),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                            : const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("Keine Schichten"),
                        ),
                      ],
                    ),
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
