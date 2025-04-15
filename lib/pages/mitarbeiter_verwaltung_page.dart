// lib/pages/mitarbeiter_verwaltung_page.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MitarbeiterVerwaltungPage extends StatefulWidget {
  const MitarbeiterVerwaltungPage({Key? key}) : super(key: key);
  @override
  _MitarbeiterVerwaltungPageState createState() =>
      _MitarbeiterVerwaltungPageState();
}

class _MitarbeiterVerwaltungPageState extends State<MitarbeiterVerwaltungPage> {
  List<Employee> employees = [];

  Future<void> _loadEmployees() async {
    try {
      List<Employee> fetched = await ApiService.fetchEmployees();
      setState(() {
        employees = fetched;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
    }
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

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _editUser(Employee user) {
    TextEditingController firstNameController =
    TextEditingController(text: user.firstName);
    TextEditingController lastNameController =
    TextEditingController(text: user.lastName);
    TextEditingController emailController =
    TextEditingController(text: user.email);
    String selectedRole = user.role;
    bool isActivated = user.isActivated;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Mitarbeiter bearbeiten"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: "Vorname"),
                ),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: "Nachname"),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                DropdownButton<String>(
                  value: selectedRole,
                  onChanged: (newValue) {
                    setState(() {
                      selectedRole = newValue!;
                    });
                  },
                  items: <String>["user", "admin"]
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                        value: value, child: Text(value));
                  }).toList(),
                ),
                Row(
                  children: [
                    const Text("Freigeschaltet: "),
                    Checkbox(
                        value: isActivated,
                        onChanged: (value) {
                          setState(() {
                            isActivated = value ?? false;
                          });
                        }),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Abbrechen")),
            ElevatedButton(
              onPressed: () async {
                try {
                  final result = await ApiService.updateEmployee(
                    id: user.id,
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    email: emailController.text,
                    role: selectedRole,
                    isActivated: isActivated,
                  );
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text("Mitarbeiter aktualisiert")));
                  await _loadEmployees();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Fehler: $e")));
                }
              },
              child: const Text("Speichern"),
            ),
          ],
        );
      },
    );
  }

  // Hier würden wir auch einen Löschen-Endpoint erwarten – vorerst entferne das Mitarbeiterobjekt lokal.
  Future<void> _deleteUser(int id) async {
    // Falls du einen API-Endpoint für DELETE /employees/:id implementierst,
    // kannst du diesen hier aufrufen.
    setState(() {
      employees.removeWhere((user) => user.id == id);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Mitarbeiter gelöscht")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mitarbeiter Verwaltung")),
      body: ListView.builder(
        itemCount: employees.length,
        itemBuilder: (context, index) {
          Employee user = employees[index];
          return ListTile(
            title: Text(user.name),
            subtitle: Text(
                "Email: ${user.email}\nRolle: ${user.role}\nFreigeschaltet: ${user.isActivated ? 'Ja' : 'Nein'}"),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (String value) async {
                if (value == "edit") {
                  _editUser(user);
                } else if (value == "delete") {
                  bool? confirmed =
                  await _confirmAction("Möchten Sie diesen Mitarbeiter wirklich löschen?");
                  if (confirmed == true) {
                    _deleteUser(user.id);
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem(value: "edit", child: Text("Bearbeiten")),
                const PopupMenuItem(value: "delete", child: Text("Löschen")),
              ],
            ),
          );
        },
      ),
    );
  }
}
