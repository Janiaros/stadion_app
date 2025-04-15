// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import '../models/models.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController  = TextEditingController();
  final TextEditingController _emailController     = TextEditingController();

  // Controller für die Passwortänderung
  final TextEditingController _oldPasswordController     = TextEditingController();
  final TextEditingController _newPasswordController     = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser != null) {
      _firstNameController.text = userProvider.currentUser!.firstName;
      _lastNameController.text  = userProvider.currentUser!.lastName;
      _emailController.text     = userProvider.currentUser!.email;
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        try {
          final result = await ApiService.updateEmployee(
            id: userProvider.currentUser!.id,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            email: _emailController.text,
            role: userProvider.currentUser!.role,
            isActivated: userProvider.currentUser!.isActivated,
          );
          Employee updatedUser = userProvider.currentUser!;
          updatedUser.firstName = _firstNameController.text;
          updatedUser.lastName  = _lastNameController.text;
          updatedUser.email     = _emailController.text;
          userProvider.updateUser(updatedUser);

          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Daten aktualisiert")));
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Fehler: $e")));
        }
      }
    }
  }

  Future<void> _logout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final _passwordFormKey = GlobalKey<FormState>();
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Passwort ändern"),
          content: Form(
            key: _passwordFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _oldPasswordController,
                  decoration: const InputDecoration(labelText: "Altes Passwort"),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? "Bitte das alte Passwort eingeben" : null,
                ),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(labelText: "Neues Passwort"),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? "Bitte neues Passwort eingeben" : null,
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: "Neues Passwort bestätigen"),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Bitte neues Passwort bestätigen";
                    }
                    if (value != _newPasswordController.text) {
                      return "Die Passwörter stimmen nicht überein";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen")),
            ElevatedButton(
              onPressed: () async {
                if (_passwordFormKey.currentState!.validate()) {
                  try {
                    final result = await ApiService.updatePassword(
                      employeeId: Provider.of<UserProvider>(context, listen: false).currentUser!.id,
                      newPassword: _newPasswordController.text,
                    );
                    if (result.containsKey('message')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Passwort erfolgreich geändert")));
                    } else if (result.containsKey('error')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['error'])));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Fehler beim Passwortwechsel: $e")));
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text("Speichern"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Einstellungen")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.currentUser == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: "Vorname"),
                    validator: (value) =>
                    value == null || value.isEmpty ? "Bitte Vorname eingeben" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: "Nachname"),
                    validator: (value) =>
                    value == null || value.isEmpty ? "Bitte Nachname eingeben" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                    value == null || value.isEmpty ? "Bitte Email eingeben" : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text("Daten speichern"),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _showChangePasswordDialog,
                    child: const Text("Passwort ändern"),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
