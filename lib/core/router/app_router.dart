import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:taxation_card/core/router/routes.dart';
import 'package:taxation_card/features/home/widget/home_tabs_screen.dart';
import 'package:taxation_card/features/proba_info/widget/proba_info_list_screen.dart';

final class AppRouter {
  AppRouter()
    : _router = GoRouter(
        initialLocation: AppRoutes.probaInfo.path,
        routes: [
          GoRoute(
            path: AppRoutes.probaInfo.path,
            name: AppRoutes.probaInfo.name,
            builder: (context, state) => const ProbaInfoListScreen(),
          ),
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
