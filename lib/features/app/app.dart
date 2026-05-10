import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/core/resources/theme.dart';
import 'package:taxation_card/features/deadwood/bloc/deadwood_bloc.dart';
import 'package:taxation_card/features/di/data/dependencies.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/eyes_taxation/bloc/eyes_taxation_bloc.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/permanent_PP/bloc/permanent_pp_bloc.dart';
import 'package:taxation_card/features/soils/bloc/soils_bloc.dart';
import 'package:taxation_card/features/stumps/bloc/stumps_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/bloc/taxation_characteristic_bloc.dart';
import 'package:taxation_card/features/undergrowth/bloc/undergrowth_bloc.dart';

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
          BlocProvider<MainTabsBloc>.value(value: _dependencies.mainTabsBloc),
          BlocProvider<EyesTaxationBloc>.value(
            value: _dependencies.eyesTaxationBloc,
          ),
          BlocProvider<PermanentPpBloc>.value(
            value: _dependencies.permanentPpBloc,
          ),
          BlocProvider<UndergrowthBloc>.value(
            value: _dependencies.undergrowthBloc,
          ),
          BlocProvider<DeadwoodBloc>.value(value: _dependencies.deadwoodBloc),
          BlocProvider<StumpsBloc>.value(value: _dependencies.stumpsBloc),
          BlocProvider<SoilsBloc>.value(value: _dependencies.soilsBloc),
          BlocProvider<TaxationCharacteristicBloc>.value(
            value: _dependencies.taxationCharacteristicBloc,
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
