import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'employee_time_details_page.dart';

class MitarbeiterZeiterfassungPage extends StatefulWidget {
  const MitarbeiterZeiterfassungPage({Key? key}) : super(key: key);

  @override
  _MitarbeiterZeiterfassungPageState createState() =>
      _MitarbeiterZeiterfassungPageState();
}

class _MitarbeiterZeiterfassungPageState
    extends State<MitarbeiterZeiterfassungPage> {
  List<Employee> employees = [];
  // Map, in der für jeden Mitarbeiter (key: employee.id) die aggregierten Stunden gespeichert werden.
  Map<int, double> aggregatedHours = {};
  // Aktuell ausgewählter Monat; initial: aktueller Monat
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      List<Employee> fetched = await ApiService.fetchEmployees();
      setState(() {
        employees = fetched;
      });
      await _aggregateAllEmployees();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Laden der Mitarbeiter: $e")),
      );
    }
  }

  /// Aggregiert für jeden Mitarbeiter die erfassten Stunden des aktuell ausgewählten Monats.
  Future<void> _aggregateAllEmployees() async {
    Map<int, double> agg = {};
    for (Employee emp in employees) {
      try {
        List<TimeStampRecord> recs =
        await ApiService.fetchTimeRecords(employeeId: emp.id);
        double sum = 0;
        // Summiere alle Zeiteinträge, die im ausgewählten Monat liegen.
        for (var rec in recs) {
          if (rec.clockIn.year == selectedMonth.year &&
              rec.clockIn.month == selectedMonth.month) {
            sum += rec.hours;
          }
        }
        agg[emp.id] = sum;
      } catch (e) {
        agg[emp.id] = 0;
      }
    }
    setState(() {
      aggregatedHours = agg;
    });
  }

  /// Kopiert einen Bericht aller Mitarbeiter mit ihren aggregierten Stunden in die Zwischenablage.
  void _copyEmployeeHoursReport() {
    StringBuffer report = StringBuffer();
    for (Employee emp in employees) {
      double hours = aggregatedHours[emp.id] ?? 0;
      report.writeln("${emp.name}\t${hours.toStringAsFixed(2)} Stunden");
    }
    Clipboard.setData(ClipboardData(text: report.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mitarbeiterstundenbericht kopiert!")),
    );
  }

  /// Ändert den aktuell ausgewählten Monat und aggregiert die Stunden neu.
  Future<void> _changeMonth(int delta) async {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + delta);
    });
    await _aggregateAllEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mitarbeiter Zeiterfassung"),
      ),
      body: Column(
        children: [
          // Monatsnavigation oben
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadEmployees,
              child: ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  Employee emp = employees[index];
                  double hours = aggregatedHours[emp.id] ?? 0;
                  return ListTile(
                    // Der Name wird nur angezeigt, ohne dass onTap eine Navigation auslöst.
                    title: Text(emp.name),
                    subtitle: Text("Gesamtstunden: ${hours.toStringAsFixed(2)} h"),
                    // Statt onTap navigiert hier _nur_ der Button zum Hinzufügen neuer Zeiteinträge.
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        // Navigiere zur editierbaren Detailansicht (editable: true) für diesen Mitarbeiter.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmployeeTimeDetailsPage(
                              employee: emp,
                              editable: true,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      // FAB zum Kopieren des Berichts der gesamten Mitarbeiterstunden
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        child: const Icon(Icons.copy, color: Colors.white),
        tooltip: "Mitarbeiterstundenbericht kopieren",
        onPressed: _copyEmployeeHoursReport,
      ),
      // Unten als Box werden die Gesamtkosten (Gesamte Stunden aller Mitarbeiter * 12,82) angezeigt.
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.grey[200],
        child: Builder(builder: (context) {
          double totalHours = aggregatedHours.values.fold(0.0, (sum, elem) => sum + elem);
          double costs = totalHours * 12.82;
          return Text(
            "Mitarbeiterkosten ${ DateFormat("MMMM", "de_DE").format(selectedMonth)}: ${costs.toStringAsFixed(2)} €",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          );
        }),
      ),
    );
  }
}
