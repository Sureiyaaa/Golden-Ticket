import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/gt_hub.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/screens/hub.dart';
import 'package:golden_ticket_enterprise/screens/error.dart';
import 'package:golden_ticket_enterprise/screens/login.dart';
import 'package:golden_ticket_enterprise/screens/tickets.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class AppRoutes {
  static GoRouter getRoutes() {
    return GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => LoginPage()),
        GoRoute(
          path: '/hub',
          builder: (context, state) {

            var box = Hive.box<HiveSession>('sessionBox');
            var userSession = box.get('user');
            if (userSession == null) {
              print("No user session found in Hive!");
              return ErrorPage(errorMessage: "Unauthorized Access!");
            } else {
              print("User session found: ${userSession.user.username}");
              final signalRService =Provider.of<SignalRService>(context, listen: true);
              // Get the passed User data
              final HiveSession? session = box.get('user')!;
              return HubPage(session: session!, signalRService: signalRService);
            }
          },
        ),
        GoRoute(path: '/error', builder: (context, state) => ErrorPage()),
      ],
    );
  }
}