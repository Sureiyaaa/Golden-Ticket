import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/signalr_service.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/user.dart';
import 'package:golden_ticket_enterprise/routes.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeHive();

  final signalRService = SignalRService();

  // Ensure SignalR disconnects when the page is refreshed
  html.window.onBeforeUnload.listen((event) {
    signalRService.stopConnection();
  });

  runApp(AppInitializer(signalRService: signalRService));
}

Future<void> _initializeHive() async {
  if (!kIsWeb) {
    final appDirectory = await getApplicationCacheDirectory();
    kLocalStoragePath = appDirectory.path;
  } else {
    kLocalStoragePath = './';
  }

  usePathUrlStrategy();
  await Hive.initFlutter(kLocalStorageKey);
  Hive.registerAdapter(HiveSessionAdapter());
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox<HiveSession>('sessionBox');
}

class AppInitializer extends StatelessWidget {
  final SignalRService signalRService;
  AppInitializer({required this.signalRService});

  @override
  Widget build(BuildContext context) {
    final dataManager = DataManager(signalRService: signalRService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => dataManager),
      ],
      child: MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: true,
      routerConfig: AppRoutes.getRoutes(),
    );
  }
}
