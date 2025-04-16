// lib/pages/employee_time_details_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class EmployeeTimeDetailsPage extends StatefulWidget {
  final Employee employee;
  final bool editable;
  const EmployeeTimeDetailsPage({Key? key, required this.employee, this.editable = true}) : super(key: key);

  @override
  _EmployeeTimeDetailsPageState createState() => _EmployeeTimeDetailsPageState();
}

class _EmployeeTimeDetailsPageState extends State<EmployeeTimeDetailsPage> {
  late DateTime selectedMonth;
  // Alle Zeiteinträge (unabhängig vom Monat) werden von der API geladen.
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
      int employeeId = widget.employee.id;
      List<TimeStampRecord> fetched = await ApiService.fetchTimeRecords(employeeId: employeeId);
      setState(() {
        records = fetched;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Zeiteinträge: $e')),
      );
    }
  }

  Future<void> _loadUpcomingShifts() async {
    try {
      List<Shift> fetchedShifts = await ApiService.fetchShifts();
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime twoWeeksLater = today.add(Duration(days: 14));

      List<Shift> filtered = fetchedShifts.where((shift) {
        try {
          DateTime shiftDate = DateTime.parse(shift.date);
          bool inRange = !shiftDate.isBefore(today) && shiftDate.isBefore(twoWeeksLater.add(Duration(days: 1)));
          bool isAssigned = shift.assignedEmployees.any((emp) => emp.id == widget.employee.id);
          return inRange && isAssigned;
        } catch (e) {
          print("Fehler beim Parsen von shift.date '${shift.date}': $e");
          return false;
        }
      }).toList();

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

  /// Dialog zum Erstellen oder Bearbeiten eines Zeiteintrags.
  /// Wird beim Hinzufügen (record == null) der API-Aufruf createTimeRecord aufgerufen.
  /// Beim Bearbeiten (record != null) wird updateTimeRecord verwendet.
  Future<TimeStampRecord?> _editOrAddRecordDialog({TimeStampRecord? record}) async {
    if (!widget.editable) return Future.value(null);
    // Standard: Für neue Einträge wird das aktuelle Datum verwendet.
    DateTime defaultDate = DateTime.now();
    DateTime clockInDate = record?.clockIn ?? defaultDate;
    DateTime clockOutDate = record?.clockOut ?? defaultDate;

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
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setStateDialog) {
            return AlertDialog(
              title: Text(record != null ? "Zeiteintrag bearbeiten" : "Neuen Zeiteintrag hinzufügen"),
              content: Form(
                key: _editFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Datumsauswahl für Einstempeln:
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
                              setStateDialog(() {
                                clockInDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    // Datumsauswahl für Ausstempeln:
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
                              setStateDialog(() {
                                clockOutDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    // Textfelder für Uhrzeiten (ohne Sekunden)
                    TextFormField(
                      controller: clockInController,
                      decoration: const InputDecoration(labelText: "Einstempelzeit (HH:MM)"),
                      validator: (value) =>
                      value == null || value.isEmpty ? "Bitte Zeit eingeben" : null,
                    ),
                    TextFormField(
                      controller: clockOutController,
                      decoration: const InputDecoration(labelText: "Ausstempelzeit (HH:MM)"),
                      validator: (value) =>
                      value == null || value.isEmpty ? "Bitte Zeit eingeben" : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Abbrechen"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_editFormKey.currentState!.validate()) {
                      String inStr = clockInController.text.trim();
                      String outStr = clockOutController.text.trim();
                      // Falls der Benutzer nur "19" eingibt, hänge ":00" an
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
                        if (record == null) {
                          // Neuer Eintrag: API-Aufruf zum Erstellen
                          Map<String, dynamic> apiResult = await ApiService.createTimeRecord(
                            employeeId: widget.employee.id,
                            clockIn: newClockIn,
                            clockOut: newClockOut,
                            cashCount: "0",
                          );
                          TimeStampRecord newRecord = TimeStampRecord.fromJson(apiResult);
                          Navigator.pop(context, newRecord);
                        } else {
                          // Bestehender Eintrag: API-Aufruf zum Aktualisieren
                          Map<String, dynamic> apiResult = await ApiService.updateTimeRecord(
                            timeRecordId: record.id!,  // Non-null assertion
                            clockIn: newClockIn,
                            clockOut: newClockOut,
                            cashCount: record.cashCount,
                          );
                          TimeStampRecord updatedRecord = TimeStampRecord.fromJson(apiResult);
                          Navigator.pop(context, updatedRecord);
                        }
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
      },
    );
  }

  // Helferfunktionen zur Formatierung
  String _formatHHMM(DateTime dt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(dt.hour)}:${twoDigits(dt.minute)}";
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}";
  }

  // Dashboard-Ansicht (nicht editierbar): Zeigt alle Zeiteinträge des aktuell ausgewählten Monats und kommende Schichten.
  Widget _buildDashboardView() {
    // Filtere Zeiteinträge, die zum aktuell ausgewählten Monat gehören.
    List<TimeStampRecord> visibleRecords = records.where((rec) {
      return rec.clockIn.year == selectedMonth.year && rec.clockIn.month == selectedMonth.month;
    }).toList();
    double totalHours = visibleRecords.fold(0.0, (sum, rec) => sum + rec.hours);
    return Scaffold(
      appBar: AppBar(title: Text("${widget.employee.name} - Mein Dashboard")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anzeige der kommenden Schichten (nächste 2 Wochen)
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
            // Monatliche Navigation und Anzeige der Zeiteinträge
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
                  Text(DateFormat('MMMM yyyy', 'de_DE').format(selectedMonth),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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
              child: visibleRecords.isNotEmpty
                  ? ListView.builder(
                itemCount: visibleRecords.length,
                itemBuilder: (context, index) {
                  TimeStampRecord rec = visibleRecords[index];
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
              child: Text("Gesamte Stunden: ${totalHours.toStringAsFixed(2)} Stunden",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Editierbare Ansicht: Hier können Zeiteinträge bearbeitet, gelöscht oder neu hinzugefügt werden.
  Widget _buildEditableView() {
    List<TimeStampRecord> visibleRecords = records.where((rec) {
      return rec.clockIn.year == selectedMonth.year && rec.clockIn.month == selectedMonth.month;
    }).toList();

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
                Text(DateFormat('MMMM yyyy', 'de_DE').format(selectedMonth),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
          Expanded(
            child: ListView.builder(
              itemCount: visibleRecords.length,
              itemBuilder: (context, index) {
                TimeStampRecord rec = visibleRecords[index];
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
                            try {
                              Map<String, dynamic> apiResult = await ApiService.updateTimeRecord(
                                timeRecordId: rec.id!, // Hier wird die id benötigt.
                                clockIn: edited.clockIn,
                                clockOut: edited.clockOut,
                                cashCount: rec.cashCount, // oder edited.cashCount, falls ein neuer Wert gesetzt wurde.
                              );
                              TimeStampRecord updatedRecord = TimeStampRecord.fromJson(apiResult);
                              setState(() {
                                int idx = records.indexOf(rec);
                                records[idx] = updatedRecord;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Zeiteintrag aktualisiert")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Fehler beim Aktualisieren: $e")),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          // Hier sollte ein API-Aufruf zum Löschen erfolgen, wenn vorhanden.
                          setState(() {
                            records.remove(rec);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Zeiteintrag gelöscht")),
                          );
                        },
                      ),
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
                try {
                  Map<String, dynamic> apiResult = await ApiService.createTimeRecord(
                    employeeId: widget.employee.id,
                    clockIn: newRec.clockIn,
                    clockOut: newRec.clockOut,
                    cashCount: newRec.cashCount,
                  );
                  TimeStampRecord created = TimeStampRecord.fromJson(apiResult);
                  setState(() {
                    records.add(created);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Zeiteintrag erstellt")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Fehler beim Erstellen: $e")),
                  );
                }
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
