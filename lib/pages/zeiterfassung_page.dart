// lib/pages/zeiterfassung_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ZeiterfassungPage extends StatefulWidget {
  const ZeiterfassungPage({super.key});
  @override
  _ZeiterfassungPageState createState() => _ZeiterfassungPageState();
}

class _ZeiterfassungPageState extends State<ZeiterfassungPage> {
  bool isClockedIn = false;
  DateTime? clockInTime;
  final _cashFormKey = GlobalKey<FormState>();
  String cashCount = "";
  final TextEditingController _cashController = TextEditingController();
  int? employeeId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadClockInState();
  }

  /// Lädt die aktuell angemeldete Mitarbeiter-ID aus SharedPreferences.
  Future<void> _loadCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt("userId");
    if (id == null) {
      // Fallback zu Testzwecken – in der echten App muss der Login die userId speichern
      print("Kein userId gefunden – Fallback auf 1");
      id = 1;
    }
    setState(() {
      employeeId = id;
    });
  }

  /// Prüft, ob bereits ein Clock-In vorliegt, und lädt den gespeicherten Zeitpunkt.
  Future<void> _loadClockInState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedClockIn = prefs.getString("clockInTime");
    if (storedClockIn != null) {
      DateTime storedTime = DateTime.parse(storedClockIn);
      setState(() {
        clockInTime = storedTime;
        isClockedIn = true;
      });
    }
  }

  String formatTimeHHMM(DateTime dt) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(dt.hour)}:${twoDigits(dt.minute)}";
  }

  Future<bool?> _confirmAction(String message) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bestätigung"),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Abbrechen")),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Bestätigen")),
        ],
      ),
    );
  }

  void _confirmClockIn() async {
    bool? confirmed = await _confirmAction("Möchten Sie sich wirklich einstempeln?");
    if (confirmed == true) {
      _clockIn();
    }
  }

  void _confirmClockOut() async {
    bool? confirmed = await _confirmAction("Möchten Sie sich wirklich ausstempeln?");
    if (confirmed == true) {
      _showCashDialog();
    }
  }

  void _clockIn() async {
    DateTime now = DateTime.now();
    setState(() {
      isClockedIn = true;
      clockInTime = now;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Speichere den Clock-In-Zeitpunkt als ISO-String
    await prefs.setString("clockInTime", now.toIso8601String());
  }

  void _showCashDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nur Scheine eingeben"),
          content: Form(
            key: _cashFormKey,
            child: TextFormField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Nur Scheine",
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              (value == null || value.isEmpty) ? "Bitte Nur Scheine eingeben" : null,
              onSaved: (value) {
                cashCount = value ?? "";
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Abbrechen")),
            ElevatedButton(
              onPressed: () {
                if (_cashFormKey.currentState!.validate()) {
                  _cashFormKey.currentState!.save();
                  Navigator.pop(context);
                  _performClockOut();
                }
              },
              child: const Text("Bestätigen"),
            ),
          ],
        );
      },
    );
  }

  void _performClockOut() async {
    if (employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fehler: Benutzer-ID nicht verfügbar.")),
      );
      return;
    }
    DateTime clockOutTime = DateTime.now();
    final response = await ApiService.createTimeRecord(
      employeeId: employeeId!,
      clockIn: clockInTime!,
      clockOut: clockOutTime,
      cashCount: cashCount.isNotEmpty ? cashCount : "0",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Eingestempelt: ${formatTimeHHMM(clockInTime!)}\nAusgestempelt: ${formatTimeHHMM(clockOutTime)}\nNur Scheine: $cashCount"),
      ),
    );

    // Nachdem clock out erfolgt, zurücksetzen und SharedPreferences leeren.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("clockInTime");

    setState(() {
      isClockedIn = false;
      clockInTime = null;
      _cashController.clear();
      cashCount = "";
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zeiterfassung")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isClockedIn
            ? Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                textStyle: const TextStyle(fontSize: 22)),
            onPressed: _confirmClockOut,
            child: const Text("Ausstempeln"),
          ),
        )
            : Center(
          child: SizedBox(
            width: 250,
            height: 80,
            child: ElevatedButton(
              onPressed: _confirmClockIn,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
              ),
              child: const Text("Einstempeln", style: TextStyle(fontSize: 24)),
            ),
          ),
        ),
      ),
    );
  }
}
