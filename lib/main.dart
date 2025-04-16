// lib/main.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'pages/splash_page.dart';

Future<void> main() async {


  // ganz kurz prüfen, ob das Gerät den Domain‑Namen auflösen kann
  try {
    final addrs = await InternetAddress.lookup('stadionspeck.de');
    print('⟳ DNS lookup stadionspeck.de → $addrs');
  } catch (e) {
    print('⟳ DNS lookup FAILED: $e');
  }

  // Stellt sicher, dass Widgets und Binding initialisiert werden
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisiere Datumsinformationen für 'de_DE'
  await initializeDateFormatting('de_DE', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stadion App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashPage(),
    );
  }
}
