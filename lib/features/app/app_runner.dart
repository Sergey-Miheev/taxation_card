import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:talker_bloc_logger/talker_bloc_logger_observer.dart';
import 'package:taxation_card/core/database/database_helper.dart';
import 'package:taxation_card/core/router/app_router.dart';
import 'package:taxation_card/features/app/app.dart';
import 'package:taxation_card/features/deadwood/bloc/deadwood_bloc.dart';
import 'package:taxation_card/features/deadwood/domain/deadwood_repository.dart';
import 'package:taxation_card/features/di/data/dependencies.dart';
import 'package:taxation_card/features/eyes_taxation/bloc/eyes_taxation_bloc.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/home/domain/home_csv_exporter.dart';
import 'package:taxation_card/features/permanent_PP/bloc/permanent_pp_bloc.dart';
import 'package:taxation_card/features/permanent_PP/domain/subjects_repository.dart';
import 'package:taxation_card/features/permanent_PP/domain/tree_information_repository.dart';
import 'package:taxation_card/features/proba_info/domain/forestry_repository.dart';
import 'package:taxation_card/features/proba_info/domain/proba_info_repository.dart';
import 'package:taxation_card/features/soils/bloc/soils_bloc.dart';
import 'package:taxation_card/features/soils/domain/soils_repository.dart';
import 'package:taxation_card/features/stumps/bloc/stumps_bloc.dart';
import 'package:taxation_card/features/stumps/domain/stumps_repository.dart';
import 'package:taxation_card/features/taxation_characteristic/bloc/taxation_characteristic_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/domain/taxation_characteristic_repository.dart';
import 'package:taxation_card/features/undergrowth/bloc/undergrowth_bloc.dart';
import 'package:taxation_card/features/undergrowth/domain/undergrowth_repository.dart';
import 'package:taxation_card/features/understory/domain/understory_repository.dart';

final class AppRunner {
  const AppRunner();

  Future<void> initializeAndRun() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (kDebugMode) {
      Bloc.observer = TalkerBlocObserver();
    }

    final database = await DatabaseHelper.instance.database;
    final subjectsRepository = SubjectsRepository(database: database);
    final forestryRepository = ForestryRepository(database: database);
    final probaInfoRepository = ProbaInfoRepository(database: database);
    final treeInformationRepository = TreeInformationRepository(
      database: database,
    );
    final taxationCharacteristicRepository = TaxationCharacteristicRepository(
      database: database,
    );
    final undergrowthRepository = UndergrowthRepository(database: database);
    final understoryRepository = UnderstoryRepository(database: database);
    final deadwoodRepository = DeadwoodRepository(database: database);
    final stumpsRepository = StumpsRepository(database: database);
    final soilsRepository = SoilsRepository(database: database);
    final homeCsvExporter = HomeCsvExporter(database: database);
    final taxationCharacteristicBloc = TaxationCharacteristicBloc(
      repository: taxationCharacteristicRepository,
    );

    final dependencies = Dependencies(
      mainTabsBloc: MainTabsBloc(),
      eyesTaxationBloc: EyesTaxationBloc(),
      permanentPpBloc: PermanentPpBloc(repository: treeInformationRepository),
      undergrowthBloc: UndergrowthBloc(),
      deadwoodBloc: DeadwoodBloc(repository: deadwoodRepository),
      stumpsBloc: StumpsBloc(repository: stumpsRepository),
      soilsBloc: SoilsBloc(),
      taxationCharacteristicBloc: taxationCharacteristicBloc,
      subjectsRepository: subjectsRepository,
      forestryRepository: forestryRepository,
      probaInfoRepository: probaInfoRepository,
      treeInformationRepository: treeInformationRepository,
      deadwoodRepository: deadwoodRepository,
      stumpsRepository: stumpsRepository,
      soilsRepository: soilsRepository,
      taxationCharacteristicRepository: taxationCharacteristicRepository,
      undergrowthRepository: undergrowthRepository,
      understoryRepository: understoryRepository,
      homeCsvExporter: homeCsvExporter,
    );

    runApp(App(routerConfig: AppRouter().config, dependencies: dependencies));
  }
}
