import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/gt_hub.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/user.dart';
import 'package:golden_ticket_enterprise/routes.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

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
  // Open the box
  await Hive.openBox<HiveSession>('sessionBox');

  runApp(
   MultiProvider(
      providers: [
       ChangeNotifierProvider(create: (_) => DataManager()),
       ChangeNotifierProvider(create: (_) => SignalRService())
     ],
     child: MyApp()
   )
  );

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