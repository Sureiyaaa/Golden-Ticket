import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/screens/hub.dart';
import 'package:golden_ticket_enterprise/screens/error.dart';
import 'package:golden_ticket_enterprise/screens/login.dart';
import 'package:golden_ticket_enterprise/screens/chatroom_page.dart';
import 'package:golden_ticket_enterprise/subscreens/chatroom_list_page.dart';
import 'package:golden_ticket_enterprise/subscreens/dashboard_page.dart';
import 'package:golden_ticket_enterprise/subscreens/faq_page.dart';
import 'package:golden_ticket_enterprise/subscreens/reports_page.dart';
import 'package:golden_ticket_enterprise/subscreens/settings_page.dart';
import 'package:golden_ticket_enterprise/subscreens/tickets_page.dart';
import 'package:golden_ticket_enterprise/subscreens/user_management.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class AppRoutes {
  static GoRouter getRoutes() {
    return GoRouter(
      initialLocation: Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : '/hub/dashboard',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => LoginPage()),
        StatefulShellRoute.indexedStack(
          redirect: (context, state) => Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : null,
          builder: (context, state, navigationShell){
            var userSession = Hive.box<HiveSession>('sessionBox').get('user');
            return StatefulBuilder(builder: (context, builder) {

              return HubPage(session: userSession, child: navigationShell, dataManager: Provider.of<DataManager>(context, listen: false));
            });
          },
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: '/hub/dashboard',
                    redirect: (context, state) => Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : null, // ✅ Redirect before building
                    name: "Dashboard",
                    pageBuilder: (context, state){
                      var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                      return NoTransitionPage(
                          key: state.pageKey,
                          child: DashboardPage(session: userSession)
                      );
                    },
                  ),
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/chatrooms',
                      redirect: (context, state) => Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : null, // ✅ Redirect before building
                      name: "Chatrooms",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        return NoTransitionPage(
                            key: state.pageKey,
                            child: ChatroomListPage(session: userSession)
                        );
                      }
                  ),
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/tickets',
                      redirect: (context, state) => Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : null, // ✅ Redirect before building
                      name: "Tickets",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        return NoTransitionPage(
                            key: state.pageKey,
                            child: TicketsPage(session: userSession)
                        );
                      }
                  )
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/faq',
                      redirect: (context, state) => Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : null, // ✅ Redirect before building
                      name: "FAQ",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        return NoTransitionPage(
                            key: state.pageKey,
                            child: FAQPage(session: userSession)
                        );
                      }
                  )
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/reports',
                      redirect: (context, state) => Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : null, // ✅ Redirect before building
                      name: "Reports",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        return NoTransitionPage(
                            key: state.pageKey,
                            child: ReportsPage(session: userSession)
                        );
                      }
                  )
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/usermanagement',
                      redirect: (context, state) => Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : null, // ✅ Redirect before building
                      name: "User Management",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        return NoTransitionPage(
                            key: state.pageKey,
                            child: UserManagementPage(session: userSession)
                        );
                      }
                  )
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/settings',
                      redirect: (context, state) => Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : null, // ✅ Redirect before building
                      name: "Settings",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        return NoTransitionPage(
                            key: state.pageKey,
                            child: SettingsPage(session: userSession)
                        );
                      }
                  )
                ]
            )
          ],
        ),
        GoRoute(
          path: '/hub/chatroom/:chatroomID',
          builder: (context, state) {
            final chatroomID = int.tryParse(state.pathParameters['chatroomID']!);
            if (chatroomID == null) {
              return ErrorPage(errorMessage: 'Invalid chatroom ID');
            }
            return ChatroomPage(chatroomID: chatroomID);
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
