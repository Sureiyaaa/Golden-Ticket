import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/screens/dashboard.dart';
import 'package:golden_ticket_enterprise/screens/error.dart';
import 'package:golden_ticket_enterprise/screens/login.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String error = '/error';

  static GoRouter getRoutes() {
    return GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => LoginPage()),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) {
            final User user = state.extra as User;  // Get the passed User data
            return DashboardPage(user: user);
          },
        ),
        GoRoute(path: '/error', builder: (context, state) => ErrorPage()),
      ],
    );
  }
}