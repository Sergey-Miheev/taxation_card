import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:talker_bloc_logger/talker_bloc_logger_observer.dart';
import 'package:taxation_card/core/database/database_helper.dart';
import 'package:taxation_card/core/router/app_router.dart';
import 'package:taxation_card/features/app/app.dart';
import 'package:taxation_card/features/deadwood/bloc/deadwood_bloc.dart';
import 'package:taxation_card/features/di/data/dependencies.dart';
import 'package:taxation_card/features/eyes_taxation/bloc/eyes_taxation_bloc.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/permanent_PP/bloc/permanent_pp_bloc.dart';
import 'package:taxation_card/features/permanent_PP/domain/subjects_repository.dart';
import 'package:taxation_card/features/permanent_PP/domain/tree_information_repository.dart';
import 'package:taxation_card/features/proba_info/domain/proba_info_repository.dart';
import 'package:taxation_card/features/soils/bloc/soils_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/bloc/taxation_characteristic_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/domain/taxation_characteristic_repository.dart';
import 'package:taxation_card/features/undergrowth/bloc/undergrowth_bloc.dart';

final class AppRunner {
  const AppRunner();

  Future<void> initializeAndRun() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (kDebugMode) {
      Bloc.observer = TalkerBlocObserver();
    }

    final database = await DatabaseHelper.instance.database;
    final subjectsRepository = SubjectsRepository(database: database);
    final probaInfoRepository = ProbaInfoRepository(database: database);
    final treeInformationRepository = TreeInformationRepository(
      database: database,
    );
    final taxationCharacteristicRepository = TaxationCharacteristicRepository(
      database: database,
    );
    final taxationCharacteristicBloc = TaxationCharacteristicBloc(
      repository: taxationCharacteristicRepository,
    )..add(const TaxationCharacteristicEvent.loaded());

    final dependencies = Dependencies(
      mainTabsBloc: MainTabsBloc(),
      eyesTaxationBloc: EyesTaxationBloc(),
      permanentPpBloc: PermanentPpBloc(repository: treeInformationRepository),
      undergrowthBloc: UndergrowthBloc(),
      deadwoodBloc: DeadwoodBloc(),
      soilsBloc: SoilsBloc(),
      taxationCharacteristicBloc: taxationCharacteristicBloc,
      subjectsRepository: subjectsRepository,
      probaInfoRepository: probaInfoRepository,
      treeInformationRepository: treeInformationRepository,
      taxationCharacteristicRepository: taxationCharacteristicRepository,
    );

    runApp(App(routerConfig: AppRouter().config, dependencies: dependencies));
  }
}
