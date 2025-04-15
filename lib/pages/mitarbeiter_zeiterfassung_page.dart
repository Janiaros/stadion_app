// lib/pages/mitarbeiter_zeiterfassung_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/data_service.dart';
import 'employee_time_details_page.dart';

class MitarbeiterZeiterfassungPage extends StatefulWidget {
  const MitarbeiterZeiterfassungPage({super.key});
  @override
  _MitarbeiterZeiterfassungPageState createState() => _MitarbeiterZeiterfassungPageState();
}

class _MitarbeiterZeiterfassungPageState extends State<MitarbeiterZeiterfassungPage> {
  // Statt Dummy-Daten jetzt leeres Array
  List<Employee> employees = [];

  // Lade Mitarbeiter vom Backend
  Future<void> _loadEmployees() async {
    try {
      List<Employee> fetched = await ApiService.fetchEmployees();
      setState(() {
        employees = fetched;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler beim Laden der Mitarbeiter: $e')));
    }
  }

  // Aggregiert Stunden aus lokalen timeRecords (diese Logik musst du ggf. später anpassen, falls auch hier echte API-Daten verwendet werden sollen)
  Map<String, double> _aggregateHours(DateTime month) {
    Map<String, double> agg = {};
    for (var emp in employees) {
      double total = 0;
      // Hier wird noch ein Dummy aus data_service.dart verwendet. Falls du echte Zeiteinträge vom Backend lädst,
      // musst du diese Funktion anpassen.
      if (timeRecords.containsKey(emp.email)) {
        for (var rec in timeRecords[emp.email]!) {
          if (rec.clockIn.year == month.year && rec.clockIn.month == month.month) {
            total += rec.hours;
          }
        }
      }
      agg[emp.email] = total;
    }
    return agg;
  }

  void _exportData() {
    DateTime now = DateTime.now();
    Map<String, double> agg = _aggregateHours(DateTime(now.year, now.month));
    String exportText = agg.entries
        .map((e) => "${e.key}: ${e.value.toStringAsFixed(2)} Stunden")
        .join("\n\n");
    Clipboard.setData(ClipboardData(text: exportText));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Daten in die Zwischenablage kopiert")));
  }

  // Falls du einen Lösch-Endpoint implementierst, kannst du diesen später hier aufrufen.
  Future<void> _deleteUser(int id) async {
    // Vorerst entfernen wir den Eintrag lokal.
    setState(() {
      employees.removeWhere((user) => user.id == id);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Mitarbeiter gelöscht")));
  }

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mitarbeiter Zeiterfassung")),
      body: employees.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: employees.length,
        itemBuilder: (context, index) {
          Employee user = employees[index];
          Map<String, double> agg = _aggregateHours(DateTime.now());
          return ListTile(
            title: Text(user.name),
            subtitle: Text("Gesamtstunden: ${agg[user.email]?.toStringAsFixed(2) ?? '0.00'}"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EmployeeTimeDetailsPage(employee: user, editable: true),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportData,
        tooltip: "Exportiere Daten des aktuellen Monats",
        child: const Icon(Icons.copy),
      ),
    );
  }
}
