// lib/pages/appointment_form_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';

class AppointmentFormPage extends StatefulWidget {
  final Appointment? initialAppointment;
  const AppointmentFormPage({Key? key, this.initialAppointment})
      : super(key: key);

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Pflichtfelder: Titel und Datum (intern im ISO-Format "YYYY-MM-DD")
  late String _title;
  late String _date;
  // Controller für das Datumstextfeld; Anzeige im Format "DD-MM-YYYY"
  late TextEditingController _dateController;

  // Optionale Felder: "Zeit von" und "Zeit bis", Name und Notiz.
  // Das überflüssige Feld "Uhrzeit" wurde entfernt.
  String _timeFrom = "";
  String _timeTo = "";
  String _person = "";
  String _note = "";

  @override
  void initState() {
    super.initState();
    if (widget.initialAppointment != null) {
      _title = widget.initialAppointment!.title;
      _date = widget.initialAppointment!.date.toIso8601String().split('T')[0];
      _dateController = TextEditingController(
          text: DateFormat("dd-MM-yyyy").format(widget.initialAppointment!.date));
      _timeFrom = widget.initialAppointment!.timeFrom ?? "";
      _timeTo = widget.initialAppointment!.timeTo ?? "";
      _person = widget.initialAppointment!.person ?? "";
      _note = widget.initialAppointment!.note ?? "";
    } else {
      _title = "";
      _date = "";
      _dateController = TextEditingController();
      _timeFrom = "";
      _timeTo = "";
      _person = "";
      _note = "";
    }
  }

  /// Normalisiert einen Zeiteingabestring:
  /// Gibt "12" zu "12:00:00", "12:30" zu "12:30:00" zurück.
  String normalizeTime(String input) {
    if (input.isEmpty) return "";
    if (!input.contains(':')) {
      return "$input:00:00";
    }
    List<String> parts = input.split(':');
    if (parts.length == 2) {
      return "${parts[0]}:${parts[1]}:00";
    }
    // Falls bereits Sekunden eingegeben wurden, ignoriere sie.
    return "${parts[0]}:${parts[1]}:00";
  }

  Future<void> _saveAppointment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Normalisiere die optionalen Zeiten (falls eingegeben)
      String normTimeFrom = normalizeTime(_timeFrom);
      String normTimeTo   = normalizeTime(_timeTo);
      try {
        Appointment saved;
        if (widget.initialAppointment == null) {
          // Neuen Termin erstellen
          saved = await ApiService.createAppointment(
            title: _title,
            date: DateTime.parse(_date),
            timeFrom: normTimeFrom.isNotEmpty ? normTimeFrom : null,
            timeTo: normTimeTo.isNotEmpty ? normTimeTo : null,
            person: _person.isNotEmpty ? _person : null,
            note: _note.isNotEmpty ? _note : null,
          );
        } else {
          saved = await ApiService.updateAppointment(
            id: widget.initialAppointment!.id,
            title: _title,
            date: DateTime.parse(_date),
            timeFrom: normTimeFrom.isNotEmpty ? normTimeFrom : null,
            timeTo: normTimeTo.isNotEmpty ? normTimeTo : null,
            person: _person.isNotEmpty ? _person : null,
            note: _note.isNotEmpty ? _note : null,
          );
        }
        Navigator.pop(context, saved);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Fehler beim Speichern: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialAppointment != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Termin bearbeiten" : "Neuen Termin erstellen"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Pflichtfeld: Titel
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: "Titel *"),
                validator: (value) => (value == null || value.isEmpty) ? "Bitte Titel eingeben" : null,
                onSaved: (value) => _title = value!.trim(),
              ),
              const SizedBox(height: 8),
              // Pflichtfeld: Datum (readOnly, Auswahl über DatePicker)
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "Datum (DD-MM-YYYY) *",
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                validator: (value) => (value == null || value.isEmpty) ? "Bitte Datum eingeben" : null,
                onTap: () async {
                  DateTime initialDate = widget.initialAppointment?.date ?? DateTime.now();
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    // Intern im ISO-Format speichern
                    _date = pickedDate.toIso8601String().split('T')[0];
                    setState(() {
                      // Feld anzeigen im Format DD-MM-YYYY
                      _dateController.text = DateFormat("dd-MM-yyyy").format(pickedDate);
                    });
                  }
                },
                onSaved: (value) {
                  // Bereits in _date gespeichert
                },
              ),
              const SizedBox(height: 8),
              // Optionale Felder: Zeit von, Zeit bis
              TextFormField(
                initialValue: _timeFrom,
                decoration: const InputDecoration(labelText: "Zeit von (optional, HH:MM)"),
                onSaved: (value) => _timeFrom = value?.trim() ?? "",
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _timeTo,
                decoration: const InputDecoration(labelText: "Zeit bis (optional, HH:MM)"),
                onSaved: (value) => _timeTo = value?.trim() ?? "",
              ),
              const SizedBox(height: 8),
              // Optionale Felder: Name/Person, Notiz
              TextFormField(
                initialValue: _person,
                decoration: const InputDecoration(labelText: "Name/Person (optional)"),
                onSaved: (value) => _person = value?.trim() ?? "",
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _note,
                decoration: const InputDecoration(labelText: "Notiz (optional)"),
                maxLines: 3,
                onSaved: (value) => _note = value?.trim() ?? "",
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _saveAppointment,
                  child: Text(isEditing ? "Änderungen speichern" : "Termin erstellen"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
