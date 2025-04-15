// lib/models/appointment.dart
class Appointment {
  final int id;
  final String title;
  final DateTime date;
  final String? time;      // optional: z. B. "14:00"
  final String? person;    // optional
  final String? timeFrom;  // optional
  final String? timeTo;    // optional
  final String? note;      // optional

  Appointment({
    required this.id,
    required this.title,
    required this.date,
    this.time,
    this.person,
    this.timeFrom,
    this.timeTo,
    this.note,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      time: json['time'] != null ? json['time'].toString() : null,
      person: json['person'] != null ? json['person'].toString() : null,
      timeFrom: json['time_from'] != null ? json['time_from'].toString() : null,
      timeTo: json['time_to'] != null ? json['time_to'].toString() : null,
      note: json['note'] != null ? json['note'].toString() : null,
    );
  }
}
