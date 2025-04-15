// lib/pages/appointment_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import 'appointment_form_page.dart';

class AppointmentDetailPage extends StatelessWidget {
  final Appointment appointment;
  const AppointmentDetailPage({Key? key, required this.appointment}) : super(key: key);

  /// Kürzt einen Zeit-String von "HH:MM:SS" auf "HH:MM".
  String _displayTime(String? time) {
    if (time == null || time.isEmpty) return "";
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Termindetails"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentFormPage(initialAppointment: appointment),
                ),
              );
              if (updated != null) {
                Navigator.pop(context, updated);
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Titel: ${appointment.title}", style: const TextStyle(fontSize: 16)),
            Text("Datum: ${DateFormat('dd.MM.yyyy').format(appointment.date)}", style: const TextStyle(fontSize: 16)),
            if (appointment.timeFrom != null && appointment.timeTo != null)
              Text("Zeitraum: ${_displayTime(appointment.timeFrom)} - ${_displayTime(appointment.timeTo)}", style: const TextStyle(fontSize: 16)),
            if (appointment.person != null && appointment.person!.isNotEmpty)
              Text("Name: ${appointment.person}", style: const TextStyle(fontSize: 16)),
            if (appointment.note != null && appointment.note!.isNotEmpty)
              Text("Notiz: ${appointment.note}", style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
