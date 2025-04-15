import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final result = await ApiService.register(
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        password: _passwordController.text,
      );
      // Prüfe die Rückgabe (z.B. ob ein error-Feld vorhanden ist)
      if (result.containsKey('message')) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result['message'])));
        Navigator.pop(context);
      } else if (result.containsKey('error')) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result['error'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrierung")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: "Vorname"),
                validator: (value) => value == null || value.isEmpty ? "Bitte Vorname eingeben" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: "Nachname"),
                validator: (value) => value == null || value.isEmpty ? "Bitte Nachname eingeben" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || value.isEmpty ? "Bitte Email eingeben" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Passwort"),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? "Bitte Passwort eingeben" : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _register,
                child: const Text("Registrieren"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
