import 'package:expense_mate/features/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/groups/presentation/groups_screen.dart';
import '../features/groups/presentation/group_detail_screen.dart';

GoRouter createRouter() => GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(path: '/groups', builder: (_, __) => const GroupsScreen()),
    GoRoute(
      path: '/groups/:id',
      builder: (ctx, st) => GroupDetailScreen(groupId: st.pathParameters['id']!),
    ),
  ],
);
