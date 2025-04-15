// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/user_provider.dart';
import 'login_page.dart';
import 'weekly_calendar_page.dart';
import 'zeiterfassung_page.dart';
import 'employee_time_details_page.dart';
import 'mitarbeiter_zeiterfassung_page.dart';
import 'mitarbeiter_verwaltung_page.dart';
import 'settings_page.dart';
// Neuen Kalender-Button hinzufügen – importiere dazu die Datei:
import 'calendar_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Employee? currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Stadion Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // Wochenkalender
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WeeklyCalendarPage()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 48),
                  SizedBox(height: 8),
                  Text("Wochenkalender", textAlign: TextAlign.center),
                ],
              ),
            ),
            // Zeiterfassung (Mitarbeiter)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ZeiterfassungPage()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 48),
                  SizedBox(height: 8),
                  Text("Zeiterfassung", textAlign: TextAlign.center),
                ],
              ),
            ),
            // Mein Dashboard
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployeeTimeDetailsPage(
                      employee: currentUser,
                      editable: false,
                    ),
                  ),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard, size: 48),
                  SizedBox(height: 8),
                  Text("Mein Dashboard", textAlign: TextAlign.center),
                ],
              ),
            ),
            // Mitarbeiter Zeiterfassung
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MitarbeiterZeiterfassungPage()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 48),
                  SizedBox(height: 8),
                  Text("Mitarbeiter\nZeiterfassung", textAlign: TextAlign.center),
                ],
              ),
            ),
            // Mitarbeiter Verwaltung
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MitarbeiterVerwaltungPage()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 48),
                  SizedBox(height: 8),
                  Text("Mitarbeiter\nVerwaltung", textAlign: TextAlign.center),
                ],
              ),
            ),
            // Einstellungen
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings, size: 48),
                  SizedBox(height: 8),
                  Text("Einstellungen", textAlign: TextAlign.center),
                ],
              ),
            ),
            // Neuer Button: Kalender (Termine)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarPage()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event, size: 48),
                  SizedBox(height: 8),
                  Text("Kalender", textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
