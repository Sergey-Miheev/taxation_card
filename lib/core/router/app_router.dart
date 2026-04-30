import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:taxation_card/core/router/routes.dart';
import 'package:taxation_card/features/main_info/widget/main_info_screen.dart';
import 'package:taxation_card/features/permanent_PP/widget/permanent_pp_screen.dart';

final class AppRouter {
  AppRouter()
    : _router = GoRouter(
        initialLocation: AppRoutes.home.path,
        routes: [
          GoRoute(
            path: AppRoutes.home.path,
            name: AppRoutes.home.name,
            builder: (context, state) => const MainInfoScreen(),
          ),
          GoRoute(
            path: AppRoutes.permanentPp.path,
            name: AppRoutes.permanentPp.name,
            builder: (context, state) => const PermanentPpScreen(),
          ),
        ],
      );

  final GoRouter _router;

  RouterConfig<Object> get config => _router;
}
