import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'widgets/rotating_plant.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const ProviderScope(child: FlorestApp()));
}

class FlorestApp extends StatelessWidget {
  const FlorestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'florest',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // One shared ticker drives every idle plant rotation in the app.
      builder: (context, child) =>
          IdleRotationScope(child: child ?? const SizedBox.shrink()),
      home: const HomeScreen(),
    );
  }
}
