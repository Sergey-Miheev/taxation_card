import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:talker_bloc_logger/talker_bloc_logger_observer.dart';
import 'package:taxation_card/core/database/database_helper.dart';
import 'package:taxation_card/core/router/app_router.dart';
import 'package:taxation_card/features/app/app.dart';
import 'package:taxation_card/features/di/data/dependencies.dart';
import 'package:taxation_card/features/main_info/bloc/main_info_bloc.dart';
import 'package:taxation_card/features/permanent_PP/bloc/permanent_pp_bloc.dart';
import 'package:taxation_card/features/permanent_PP/domain/subjects_repository.dart';

final class AppRunner {
  const AppRunner();

  Future<void> initializeAndRun() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (kDebugMode) {
      Bloc.observer = TalkerBlocObserver();
    }

    final database = await DatabaseHelper.instance.database;
    final subjectsRepository = SubjectsRepository(database: database);

    final dependencies = Dependencies(
      mainInfoBloc: MainInfoBloc(),
      permanentPpBloc: PermanentPpBloc(),
      subjectsRepository: subjectsRepository,
    );

    runApp(App(routerConfig: AppRouter().config, dependencies: dependencies));
  }
}
