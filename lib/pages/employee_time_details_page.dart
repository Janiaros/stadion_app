// lib/pages/employee_time_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class EmployeeTimeDetailsPage extends StatefulWidget {
  final Employee employee;
  final bool editable;
  const EmployeeTimeDetailsPage({Key? key, required this.employee, this.editable = true})
      : super(key: key);
  @override
  _EmployeeTimeDetailsPageState createState() => _EmployeeTimeDetailsPageState();
}

class _EmployeeTimeDetailsPageState extends State<EmployeeTimeDetailsPage> {
  late DateTime selectedMonth;
  List<TimeStampRecord> records = [];
  List<Shift> upcomingShifts = []; // Kommende Schichten (nächste 2 Wochen)

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);
    _loadTimeRecords();
    _loadUpcomingShifts();
  }

  Future<void> _loadTimeRecords() async {
    try {
      // In einer echten App beziehst du die Mitarbeiter-ID aus den Login-Daten
      int employeeId = widget.employee.id;
      List<TimeStampRecord> fetched = await ApiService.fetchTimeRecords(employeeId: employeeId);
      setState(() {
        records = fetched;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Zeiteinträge: $e')));
    }
  }

  Future<void> _loadUpcomingShifts() async {
    try {
      // Alle Schichten laden
      List<Shift> fetchedShifts = await ApiService.fetchShifts();
      DateTime now = DateTime.now();
      // Erzeuge ein "heutiges Datum" ohne Uhrzeit (nur Jahr, Monat, Tag)
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime twoWeeksLater = today.add(Duration(days: 14));

      // Filtere Schichten: Sie müssen heute oder später liegen und innerhalb von 2 Wochen enden.
      // Außerdem muss der aktuell eingeloggte Mitarbeiter in den zugewiesenen Mitarbeitern enthalten sein.
      List<Shift> filtered = fetchedShifts.where((shift) {
        try {
          DateTime shiftDate = DateTime.parse(shift.date); // erwartet "yyyy-MM-dd"
          bool inRange = !shiftDate.isBefore(today) && shiftDate.isBefore(twoWeeksLater.add(Duration(days: 1)));
          bool isAssigned = shift.assignedEmployees.any((emp) => emp.id == widget.employee.id);
          return inRange && isAssigned;
        } catch (e) {
          print("Fehler beim Parsen von shift.date '${shift.date}': $e");
          return false;
        }
      }).toList();

      // Sortiere die Schichten: Zuerst nach Datum, dann nach Startzeit
      filtered.sort((a, b) {
        DateTime dateA = DateTime.parse(a.date);
        DateTime dateB = DateTime.parse(b.date);
        int cmp = dateA.compareTo(dateB);
        if (cmp != 0) return cmp;
        List<int> partsA = a.startTime.split(':').map(int.parse).toList();
        List<int> partsB = b.startTime.split(':').map(int.parse).toList();
        Duration durA = Duration(hours: partsA[0], minutes: partsA[1], seconds: partsA[2]);
        Duration durB = Duration(hours: partsB[0], minutes: partsB[1], seconds: partsB[2]);
        return durA.compareTo(durB);
      });

      setState(() {
        upcomingShifts = filtered;
      });
    } catch (e) {
      print("Fehler beim Laden der kommenden Schichten: $e");
    }
  }

  Future<TimeStampRecord?> _editOrAddRecordDialog({TimeStampRecord? record}) async {
    if (!widget.editable) return Future.value(null);
    DateTime clockInDate = record?.clockIn ?? selectedMonth;
    DateTime clockOutDate = record?.clockOut ?? selectedMonth;
    TextEditingController clockInController = TextEditingController(
      text: record != null ? _formatHHMM(record.clockIn) : "",
    );
    TextEditingController clockOutController = TextEditingController(
      text: record != null ? _formatHHMM(record.clockOut) : "",
    );
    final _editFormKey = GlobalKey<FormState>();
    return showDialog<TimeStampRecord>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(record != null ? "Zeiteintrag bearbeiten" : "Neuen Zeiteintrag hinzufügen"),
          content: Form(
            key: _editFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text("Einstempel-Datum: "),
                    TextButton(
                      child: Text(_formatDate(clockInDate)),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: clockInDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            clockInDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("Ausstempel-Datum: "),
                    TextButton(
                      child: Text(_formatDate(clockOutDate)),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: clockOutDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            clockOutDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
                TextFormField(
                  controller: clockInController,
                  decoration: const InputDecoration(labelText: "Einstempelzeit (HH:MM)"),
                  validator: (value) => value == null || value.isEmpty ? "Bitte Zeit eingeben" : null,
                ),
                TextFormField(
                  controller: clockOutController,
                  decoration: const InputDecoration(labelText: "Ausstempelzeit (HH:MM)"),
                  validator: (value) => value == null || value.isEmpty ? "Bitte Zeit eingeben" : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen")),
            ElevatedButton(
              onPressed: () {
                if (_editFormKey.currentState!.validate()) {
                  String inStr = clockInController.text.trim();
                  String outStr = clockOutController.text.trim();
                  if (!inStr.contains(':')) inStr = "$inStr:00";
                  if (!outStr.contains(':')) outStr = "$outStr:00";
                  try {
                    List<String> inParts = inStr.split(':');
                    List<String> outParts = outStr.split(':');
                    DateTime newClockIn = DateTime(
                      clockInDate.year,
                      clockInDate.month,
                      clockInDate.day,
                      int.parse(inParts[0]),
                      int.parse(inParts[1]),
                    );
                    DateTime newClockOut = DateTime(
                      clockOutDate.year,
                      clockOutDate.month,
                      clockOutDate.day,
                      int.parse(outParts[0]),
                      int.parse(outParts[1]),
                    );
                    if (!newClockOut.isAfter(newClockIn)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Ausstempelzeit muss nach der Einstempelzeit liegen")),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      TimeStampRecord(
                        clockIn: newClockIn,
                        clockOut: newClockOut,
                        cashCount: record?.cashCount ?? "0",
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ungültiges Zeitformat")),
                    );
                  }
                }
              },
              child: const Text("Speichern"),
            ),
          ],
        );
      },
    );
  }

  String _formatHHMM(DateTime dt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(dt.hour)}:${twoDigits(dt.minute)}";
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}";
  }

  // Hilfsmethode, um den Monatsnamen zurückzugeben
  String _formatMonth(DateTime dt) {
    List<String> months = ["", "Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"];
    return months[dt.month];
  }

  // Nicht-editierbare Ansicht: Dashboard
  Widget _buildDashboardView() {
    double totalHours = records.fold(0.0, (sum, rec) => sum + rec.hours);
    return Scaffold(
      appBar: AppBar(title: Text("${widget.employee.name} - Mein Dashboard")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bereich: Kommende Schichten (nächste 2 Wochen)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text("Meine kommenden Schichten (nächste 2 Wochen):", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            upcomingShifts.isNotEmpty
                ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcomingShifts.length,
              itemBuilder: (context, index) {
                final shift = upcomingShifts[index];
                DateTime shiftDate = DateTime.parse(shift.date);
                String displayDate = DateFormat('dd.MM.yyyy').format(shiftDate);
                return ListTile(
                  title: Text("${shift.startTime} - ${shift.endTime}"),
                  subtitle: Text("$displayDate | ${shift.description}"),
                );
              },
            )
                : const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Keine bevorstehenden Schichten gefunden."),
            ),
            const Divider(),
            // Bereich: Monatliche Navigation und Zeiteinträge
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_left),
                      onPressed: () {
                        setState(() {
                          selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                        });
                      }),
                  Text("${_formatMonth(selectedMonth)} ${selectedMonth.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.arrow_right),
                      onPressed: () {
                        DateTime nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                        setState(() {
                          selectedMonth = nextMonth;
                        });
                      }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Text("Meine Zeiteinträge:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Container(
              height: 300,
              child: records.isNotEmpty
                  ? ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  TimeStampRecord rec = records[index];
                  return ListTile(
                    title: Text(_formatDate(rec.clockIn)),
                    subtitle: Text("Einstempeln: ${_formatHHMM(rec.clockIn)}\nAusstempeln: ${_formatHHMM(rec.clockOut)}"),
                    isThreeLine: true,
                  );
                },
              )
                  : const Center(child: Text("Keine Zeiteinträge gefunden.")),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Gesamte Stunden: ${totalHours.toStringAsFixed(2)} Stunden", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Editierbare Ansicht: Nur Zeiteinträge zur Bearbeitung
  Widget _buildEditableView() {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.employee.name} - Zeiteinträge")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () {
                      setState(() {
                        selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                      });
                    }),
                Text("${_formatMonth(selectedMonth)} ${selectedMonth.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () {
                      DateTime nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                      if (nextMonth.isBefore(DateTime.now()) ||
                          (nextMonth.month == DateTime.now().month && nextMonth.year == DateTime.now().year))
                        setState(() {
                          selectedMonth = nextMonth;
                        });
                    }),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                TimeStampRecord rec = records[index];
                return ListTile(
                  title: Text(_formatDate(rec.clockIn)),
                  subtitle: Text("Einstempeln: ${_formatHHMM(rec.clockIn)}\nAusstempeln: ${_formatHHMM(rec.clockOut)}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            TimeStampRecord? edited = await _editOrAddRecordDialog(record: rec);
                            if (edited != null) {
                              setState(() {
                                records[index] = edited;
                              });
                            }
                          }),
                      IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              records.removeAt(index);
                            });
                          }),
                    ],
                  ),
                );
              },
            ),
          ),
          FloatingActionButton(
            onPressed: () async {
              TimeStampRecord? newRec = await _editOrAddRecordDialog();
              if (newRec != null) {
                setState(() {
                  records.add(newRec);
                });
              }
            },
            child: const Icon(Icons.add),
            tooltip: "Neuen Zeiteintrag hinzufügen",
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.editable ? _buildEditableView() : _buildDashboardView();
  }
}
