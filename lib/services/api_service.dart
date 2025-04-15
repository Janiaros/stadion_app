import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart'; // Für Shift, Employee, TimeStampRecord usw.
import '../models/appointment.dart'; // Für Appointment-Klasse
import 'api_helper.dart';

// Basis-URL wird jetzt ausschließlich im ApiHelper definiert

class ApiService {
  /// Registriert einen neuen Benutzer.
  static Future<Map<String, dynamic>> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final body = {
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "password": password,
    };
    final result = await ApiHelper.post('/register', body);
    return result;
  }

  /// Aktualisiert ausschließlich die Mitarbeiterzuweisungen (Shift Assignments)
  static Future<Map<String, dynamic>> updateShiftAssignments({
    required int shiftId,
    required List<int> assignedEmployeeIds,
  }) async {
    final result = await ApiHelper.put('/shifts/$shiftId/assignments', {
      "assignedEmployees": assignedEmployeeIds,
    });
    return result;
  }

  /// Führt den Login durch.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final body = {"email": email, "password": password};
    final result = await ApiHelper.post('/login', body);
    return result;
  }

  /// Holt alle Schichten aus dem Backend.
  static Future<List<Shift>> fetchShifts() async {
    final result = await ApiHelper.get('/shifts');
    List<dynamic> jsonList = result;
    return jsonList.map((json) => Shift.fromJson(json)).toList();
  }

  /// Erstellt einen neuen Shift.
  static Future<Map<String, dynamic>> createShift({
    required String shiftDate,
    required String startTime,
    required String endTime,
    required String description,
  }) async {
    final body = {
      "shiftDate": shiftDate,
      "startTime": startTime,
      "endTime": endTime,
      "description": description,
    };
    final result = await ApiHelper.post('/shifts', body);
    return result;
  }

  /// Aktualisiert einen Shift inklusive Mitarbeiterzuweisungen.
  static Future<Map<String, dynamic>> updateShift({
    required int shiftId,
    required String shiftDate,
    required String startTime,
    required String endTime,
    required String description,
    required List<int> assignedEmployeeIds,
  }) async {
    final body = {
      "shiftDate": shiftDate,
      "startTime": startTime,
      "endTime": endTime,
      "description": description,
      "assignedEmployees": assignedEmployeeIds,
    };
    final result = await ApiHelper.put('/shifts/$shiftId', body);
    return result;
  }

  /// Löscht einen Shift.
  static Future<Map<String, dynamic>> deleteShift({required int shiftId}) async {
    final result = await ApiHelper.delete('/shifts/$shiftId');
    return result;
  }

  /// Holt alle Mitarbeiter.
  static Future<List<Employee>> fetchEmployees() async {
    final result = await ApiHelper.get('/employees');
    List<dynamic> jsonList = result;
    return jsonList.map((json) => Employee.fromJson(json)).toList();
  }

  /// Holt einen einzelnen Mitarbeiter.
  static Future<Employee> fetchEmployee(int id) async {
    final result = await ApiHelper.get('/employees/$id');
    return Employee.fromJson(result);
  }

  /// Aktualisiert einen Mitarbeiter.
  static Future<Map<String, dynamic>> updateEmployee({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
    required bool isActivated,
  }) async {
    final body = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'isActivated': isActivated ? 1 : 0,
    };
    final result = await ApiHelper.put('/employees/$id', body);
    return result;
  }

  /// Aktualisiert das Passwort eines Mitarbeiters.
  static Future<Map<String, dynamic>> updatePassword({
    required int employeeId,
    required String newPassword,
  }) async {
    final body = {"newPassword": newPassword};
    final result = await ApiHelper.put('/employees/$employeeId/password', body);
    return result;
  }

  /// Erstellt einen Zeiteintrag.
  static Future<Map<String, dynamic>> createTimeRecord({
    required int employeeId,
    required DateTime clockIn,
    required DateTime clockOut,
    required String cashCount,
  }) async {
    String pad(int n) => n.toString().padLeft(2, '0');
    String convertToMySQLDateTime(DateTime dt) {
      return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}';
    }
    final body = {
      "employee_id": employeeId,
      "clockIn": convertToMySQLDateTime(clockIn),
      "clockOut": convertToMySQLDateTime(clockOut),
      "cashCount": cashCount,
    };
    final result = await ApiHelper.post('/time-records', body);
    return result;
  }

  /// Holt alle Zeiteinträge eines Mitarbeiters.
  static Future<List<TimeStampRecord>> fetchTimeRecords({required int employeeId}) async {
    final result = await ApiHelper.get('/time-records?employee_id=$employeeId');
    List<dynamic> jsonList = result;
    return jsonList.map((json) => TimeStampRecord.fromJson(json)).toList();
  }

  /// Prüft, ob das Backend erreichbar ist.
  static Future<bool> ping() async {
    try {
      final result = await ApiHelper.get('/ping');
      return result['message'] == "pong";
    } catch (e) {
      return false;
    }
  }

  // Termine (Appointments)

  static Future<List<Appointment>> fetchAppointments() async {
    final result = await ApiHelper.get('/appointments');
    List<dynamic> data = result;
    return data.map((json) => Appointment.fromJson(json)).toList();
  }

  static Future<Appointment> createAppointment({
    required String title,
    required DateTime date,
    String? time,
    String? person,
    String? timeFrom,
    String? timeTo,
    String? note,
  }) async {
    final body = jsonEncode({
      "title": title,
      "date": date.toIso8601String().split('T')[0], // Format "YYYY-MM-DD"
      "time": time,
      "person": person,
      "time_from": timeFrom,
      "time_to": timeTo,
      "note": note,
    });
    final result = await ApiHelper.post('/appointments', jsonDecode(body));
    return Appointment.fromJson(result);
  }

  static Future<Appointment> updateAppointment({
    required int id,
    required String title,
    required DateTime date,
    String? time,
    String? person,
    String? timeFrom,
    String? timeTo,
    String? note,
  }) async {
    final body = jsonEncode({
      "title": title,
      "date": date.toIso8601String().split('T')[0],
      "time": time,
      "person": person,
      "time_from": timeFrom,
      "time_to": timeTo,
      "note": note,
    });
    final result = await ApiHelper.put('/appointments/$id', jsonDecode(body));
    return Appointment.fromJson(result);
  }
}
