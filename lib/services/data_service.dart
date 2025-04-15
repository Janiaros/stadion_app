import '../models/models.dart';

/// Globaler Nutzer, der aktuell als Beispiel verwendet wird (Admin beispielsweise)
const String currentEmployeeEmail = "max@example.com";

/// Globale Liste registrierter Benutzer
List<Employee> users = [
  // Beispiel-Admin:
  Employee(
    email: "admin@example.com",
    firstName: "Admin",
    lastName: "User",
    role: "admin",
    isActivated: true,
  ),
  // Beispielbenutzer:
  Employee(
    email: "max@example.com",
    firstName: "Max",
    lastName: "Mustermann",
    role: "user",
    isActivated: true,
  ),
  // Weitere Benutzer kannst du hier hinzufügen…
];

/// Globale Speicherung der Zeiteinträge (Schlüssel: Email)
Map<String, List<TimeStampRecord>> timeRecords = {};


