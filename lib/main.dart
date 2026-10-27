import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'digital/digital_app.dart';
import 'theme/steel_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Cryptography.instance = FlutterCryptography.defaultInstance;
  runApp(const SteelApp());
}

class SteelApp extends StatelessWidget {
  const SteelApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Steel by Exo',
    debugShowCheckedModeBanner: false,
    theme: steelThemeData(),
    home: const DigitalHome(),
  );
}
