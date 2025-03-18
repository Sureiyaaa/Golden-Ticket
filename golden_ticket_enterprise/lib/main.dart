import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/routes.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    final appDirectory = await getApplicationCacheDirectory();
    kLocalStoragePath = appDirectory.path;
  } else {
    kLocalStoragePath = './';
  }

  Hive.init(kLocalStorageKey);
  usePathUrlStrategy();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRoutes.getRoutes(),
    );
  }
}