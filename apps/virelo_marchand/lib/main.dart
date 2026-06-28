import 'package:flutter/material.dart';
import 'app.dart';
import 'config/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const VireloMarchandApp());
}
