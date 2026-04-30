import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/resources/theme.dart';
import 'package:taxation_card/features/di/data/dependencies.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/main_info/bloc/main_info_bloc.dart';
import 'package:taxation_card/features/permanent_PP/bloc/permanent_pp_bloc.dart';

final class App extends StatelessWidget {
  const App({
    required RouterConfig<Object> routerConfig,
    required Dependencies dependencies,
    super.key,
  }) : _routerConfig = routerConfig,
       _dependencies = dependencies;

  final RouterConfig<Object> _routerConfig;
  final Dependencies _dependencies;

  @override
  Widget build(BuildContext context) {
    return DependenciesScope(
      dependencies: _dependencies,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<MainInfoBloc>.value(value: _dependencies.mainInfoBloc),
          BlocProvider<PermanentPpBloc>.value(
            value: _dependencies.permanentPpBloc,
          ),
        ],
        child: MaterialApp.router(
          title: 'Taxation Card',
          theme: lightTheme,
          routerConfig: _routerConfig,
        ),
      ),
    );
  }
}
