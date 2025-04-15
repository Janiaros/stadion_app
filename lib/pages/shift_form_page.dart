// lib/pages/shift_form_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/models.dart';
import '../services/api_service.dart';

class ShiftFormPage extends StatefulWidget {
  final String? initialDate;
  final Shift? initialShift;
  const ShiftFormPage({Key? key, this.initialDate, this.initialShift})
      : super(key: key);

  @override
  State<ShiftFormPage> createState() => _ShiftFormPageState();
}

class _ShiftFormPageState extends State<ShiftFormPage> {
  final _formKey = GlobalKey<FormState>();

  late String _date;
  String _startTime = "";
  String _endTime = "";
  String _description = "";

  @override
  void initState() {
    super.initState();
    if (widget.initialShift != null) {
      _date = widget.initialShift!.date;
      _startTime = widget.initialShift!.startTime; // Erwartet "HH:MM:SS"
      _endTime = widget.initialShift!.endTime;
      _description = widget.initialShift!.description;
    } else {
      _date = widget.initialDate ?? "";
    }
  }

  /// Normalisiert die eingegebene Zeit. Falls der Nutzer nur die Stunde eingibt (z. B. "19")
  /// wird daraus "19:00:00". Falls er z. B. "19:00" eingibt, wird es ebenfalls auf "19:00:00"
  /// erweitert. Falls er bereits Sekunden angibt, werden diese ignoriert.
  String normalizeTime(String input) {
    if (!input.contains(':')) {
      // Nur Stunde angegeben
      return "$input:00:00";
    }
    List<String> parts = input.split(':');
    if (parts.length == 2) {
      // HH:MM eingegeben
      return "${parts[0]}:${parts[1]}:00";
    }
    if (parts.length >= 3) {
      // Falls Sekunden angegeben, ignoriere sie und nimm HH:MM
      return "${parts[0]}:${parts[1]}:00";
    }
    return input;
  }

  Future<void> _saveShift() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Normalisiere die Zeiten: Es soll immer ohne Sekunden gespeichert werden
      _startTime = normalizeTime(_startTime);
      _endTime = normalizeTime(_endTime);

      try {
        // Erstelle die Schicht über den Backend-Endpunkt.
        final result = await ApiService.createShift(
          shiftDate: _date,        // Erwarte "yyyy-MM-dd"
          startTime: _startTime,     // z. B. "19:00:00"
          endTime: _endTime,         // z. B. "23:00:00"
          description: _description,
        );
        Navigator.pop(context, jsonEncode(result));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler beim Speichern der Schicht: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialShift != null
            ? "Schicht bearbeiten"
            : "Neue Schicht erstellen"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              widget.initialShift != null
                  ? Text("Datum: $_date",
                  style: const TextStyle(fontWeight: FontWeight.bold))
                  : TextFormField(
                initialValue: _date,
                decoration:
                const InputDecoration(labelText: "Datum (yyyy-MM-dd)"),
                validator: (value) => (value == null || value.isEmpty)
                    ? "Bitte Datum eingeben"
                    : null,
                onSaved: (value) => _date = value ?? "",
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _startTime.isNotEmpty
                    ? _startTime.substring(0, 5)
                    : "",
                decoration:
                const InputDecoration(labelText: "Startzeit (HH:MM)"),
                validator: (value) => (value == null || value.isEmpty)
                    ? "Bitte Startzeit eingeben"
                    : null,
                onSaved: (value) => _startTime = value ?? "",
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue:
                _endTime.isNotEmpty ? _endTime.substring(0, 5) : "",
                decoration:
                const InputDecoration(labelText: "Endzeit (HH:MM)"),
                validator: (value) => (value == null || value.isEmpty)
                    ? "Bitte Endzeit eingeben"
                    : null,
                onSaved: (value) => _endTime = value ?? "",
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _description,
                decoration:
                const InputDecoration(labelText: "Beschreibung"),
                validator: (value) => (value == null || value.isEmpty)
                    ? "Bitte Beschreibung eingeben"
                    : null,
                onSaved: (value) => _description = value ?? "",
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _saveShift,
                  child: Text(widget.initialShift != null
                      ? "Schicht aktualisieren"
                      : "Schicht speichern"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
