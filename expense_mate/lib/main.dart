import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ExpenseMateApp()));
}

class ExpenseMateApp extends ConsumerWidget {
  const ExpenseMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createRouter();
    return MaterialApp.router(
      title: 'ExpenseMate',
      theme: appTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
