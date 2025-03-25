import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/screens/hub.dart';
import 'package:golden_ticket_enterprise/screens/error.dart';
import 'package:golden_ticket_enterprise/screens/login.dart';
import 'package:hive/hive.dart';

class AppRoutes {
  static GoRouter getRoutes() {
    return GoRouter(
      initialLocation: Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : '/hub',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => LoginPage()),
        GoRoute(
          path: '/hub',
          redirect: (context, state) => Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : null, // ✅ Redirect before building
          builder: (context, state) {
            var userSession = Hive.box<HiveSession>('sessionBox').get('user');
            return HubPage(session: userSession);
          },
        ),
        GoRoute(
          path: '/error',
          builder: (context, state) {
            final errorMessage = state.extra as String? ?? 'An unknown error occurred';
            return ErrorPage(errorMessage: errorMessage);
          },
        ),
      ],
    );
  }
}
