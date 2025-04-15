// lib/models/models.dart
class Employee {
  int id;
  String email;
  String firstName;
  String lastName;
  String role; // z.B. "user" oder "admin"
  bool isActivated;
  String password;

  Employee({
    this.id = 0,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = "user",
    this.isActivated = false,
    this.password = "",
  });

  String get name => "$firstName $lastName";

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: json['role'],
      isActivated: json['isActivated'] == 1,
      password: json['password'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'isActivated': isActivated ? 1 : 0,
      'password': password,
    };
  }

  // Überschreibe operator == und hashCode, um auf die ID zu vergleichen
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}


class TimeStampRecord {
  DateTime clockIn;
  DateTime clockOut;
  String cashCount;

  TimeStampRecord({
    required this.clockIn,
    required this.clockOut,
    required this.cashCount,
  });

  double get hours => clockOut.difference(clockIn).inMinutes / 60;

  factory TimeStampRecord.fromJson(Map<String, dynamic> json) {
    return TimeStampRecord(
      clockIn: DateTime.parse(json['clockIn']),
      clockOut: DateTime.parse(json['clockOut']),
      cashCount: json['cashCount'].toString(),
    );
  }
}
// lib/models/models.dart
class Shift {
  final int id;
  final String date; // Reines Datum im Format "YYYY-MM-DD"
  final String startTime;
  final String endTime;
  final String description;
  List<Employee> assignedEmployees;
  List<Employee> requestedEmployees;

  Shift({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.description,
    List<Employee>? assignedEmployees,
    List<Employee>? requestedEmployees,
  })  : assignedEmployees = assignedEmployees ?? [],
        requestedEmployees = requestedEmployees ?? [];

  factory Shift.fromJson(Map<String, dynamic> json) {
    // Konvertiere das Datum, falls es in ISO-Format vorliegt
    String rawDate = (json['shiftDate'] ?? json['date'])?.toString().trim() ?? "";
    String standardizedDate = rawDate.contains('T') ? rawDate.split('T')[0] : rawDate;

    // Falls das JSON ein Feld "assignedEmployees" enthält, mappe es auf eine Liste von Employee-Objekten
    List<Employee> assigned = [];
    if (json['assignedEmployees'] != null) {
      assigned = (json['assignedEmployees'] as List)
          .map((empJson) => Employee.fromJson(empJson))
          .toList();
    }

    // Du kannst hier ähnlich auch "requestedEmployees" behandeln, falls gewünscht.
    return Shift(
      id: json['id'] ?? 0,
      date: standardizedDate,
      startTime: json['startTime'],
      endTime: json['endTime'],
      description: json['description'],
      assignedEmployees: assigned,
      // requestedEmployees: [...]  // Falls deine API auch dieses Feld liefert.
    );
  }
}





