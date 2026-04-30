import 'package:flutter/widgets.dart';
import 'package:taxation_card/features/app/app_runner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await const AppRunner().initializeAndRun();
}
