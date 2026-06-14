import 'package:taxation_card/core/database/database_exporter.dart';
import 'package:taxation_card/features/deadwood/bloc/deadwood_bloc.dart';
import 'package:taxation_card/features/deadwood/domain/deadwood_repository.dart';
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
import 'package:taxation_card/features/species/domain/species_options_controller.dart';
import 'package:taxation_card/features/stumps/bloc/stumps_bloc.dart';
import 'package:taxation_card/features/stumps/domain/stumps_repository.dart';
import 'package:taxation_card/features/taxation_characteristic/bloc/taxation_characteristic_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/domain/taxation_characteristic_repository.dart';
import 'package:taxation_card/features/undergrowth/bloc/undergrowth_bloc.dart';
import 'package:taxation_card/features/undergrowth/domain/undergrowth_repository.dart';
import 'package:taxation_card/features/understory/domain/understory_repository.dart';

final class Dependencies {
  const Dependencies({
    required this.mainTabsBloc,
    required this.eyesTaxationBloc,
    required this.permanentPpBloc,
    required this.undergrowthBloc,
    required this.deadwoodBloc,
    required this.stumpsBloc,
    required this.soilsBloc,
    required this.taxationCharacteristicBloc,
    required this.subjectsRepository,
    required this.forestryRepository,
    required this.probaInfoRepository,
    required this.treeInformationRepository,
    required this.deadwoodRepository,
    required this.stumpsRepository,
    required this.soilsRepository,
    required this.speciesOptionsController,
    required this.taxationCharacteristicRepository,
    required this.undergrowthRepository,
    required this.understoryRepository,
    required this.homeCsvExporter,
    required this.databaseExporter,
  });

  final MainTabsBloc mainTabsBloc;
  final EyesTaxationBloc eyesTaxationBloc;
  final PermanentPpBloc permanentPpBloc;
  final UndergrowthBloc undergrowthBloc;
  final DeadwoodBloc deadwoodBloc;
  final StumpsBloc stumpsBloc;
  final SoilsBloc soilsBloc;
  final TaxationCharacteristicBloc taxationCharacteristicBloc;
  final SubjectsRepository subjectsRepository;
  final ForestryRepository forestryRepository;
  final ProbaInfoRepository probaInfoRepository;
  final TreeInformationRepository treeInformationRepository;
  final DeadwoodRepository deadwoodRepository;
  final StumpsRepository stumpsRepository;
  final SoilsRepository soilsRepository;
  final SpeciesOptionsController speciesOptionsController;
  final TaxationCharacteristicRepository taxationCharacteristicRepository;
  final UndergrowthRepository undergrowthRepository;
  final UnderstoryRepository understoryRepository;
  final HomeCsvExporter homeCsvExporter;
  final DatabaseExporter databaseExporter;
}
