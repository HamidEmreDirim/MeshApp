import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/conversation_list_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/landing/presentation/landing_screen.dart' as io;
import '../../features/map/presentation/map_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/users/presentation/users_panel.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final chatNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'chat');
  final mapNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'map');
  final usersNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'users');
  final settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');
  
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/landing',
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/landing';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/landing',
        builder: (context, state) => const io.LandingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: chatNavigatorKey,
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ConversationListScreen(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      return ChatScreen(
                        targetNodeId: extra['nodeId'] as int,
                        targetName: extra['name'] as String,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: mapNavigatorKey,
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: usersNavigatorKey,
            routes: [
              GoRoute(
                path: '/users',
                builder: (context, state) => const UsersPanel(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
