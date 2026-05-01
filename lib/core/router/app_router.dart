import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:taxation_card/core/router/routes.dart';
import 'package:taxation_card/features/home/widget/home_tabs_screen.dart';

final class AppRouter {
  AppRouter()
    : _router = GoRouter(
        initialLocation: AppRoutes.home.path,
        routes: [
          GoRoute(
            path: AppRoutes.home.path,
            name: AppRoutes.home.name,
            builder: (context, state) => const HomeTabsScreen(),
          ),
        ],
      );

  final GoRouter _router;

  RouterConfig<Object> get config => _router;
}
