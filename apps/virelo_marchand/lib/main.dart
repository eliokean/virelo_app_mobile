import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'config/di/injection.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:virelo_core/virelo_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await PushNotificationService().init();
  await initializeDateFormatting('fr_FR', null);
  await initDependencies();
  runApp(const VireloMarchandApp());
}
