import 'package:taxation_card/features/deadwood/bloc/deadwood_bloc.dart';
import 'package:taxation_card/features/home/bloc/main_tabs_bloc.dart';
import 'package:taxation_card/features/main_info/bloc/main_info_bloc.dart';
import 'package:taxation_card/features/permanent_PP/bloc/permanent_pp_bloc.dart';
import 'package:taxation_card/features/permanent_PP/domain/subjects_repository.dart';
import 'package:taxation_card/features/permanent_PP/domain/tree_information_repository.dart';
import 'package:taxation_card/features/proba_info/domain/proba_info_repository.dart';
import 'package:taxation_card/features/soils/bloc/soils_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/bloc/taxation_characteristic_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/domain/taxation_characteristic_repository.dart';
import 'package:taxation_card/features/undergrowth/bloc/undergrowth_bloc.dart';

final class Dependencies {
  const Dependencies({
    required this.mainTabsBloc,
    required this.mainInfoBloc,
    required this.permanentPpBloc,
    required this.undergrowthBloc,
    required this.deadwoodBloc,
    required this.soilsBloc,
    required this.taxationCharacteristicBloc,
    required this.subjectsRepository,
    required this.probaInfoRepository,
    required this.treeInformationRepository,
    required this.taxationCharacteristicRepository,
  });

  final MainTabsBloc mainTabsBloc;
  final MainInfoBloc mainInfoBloc;
  final PermanentPpBloc permanentPpBloc;
  final UndergrowthBloc undergrowthBloc;
  final DeadwoodBloc deadwoodBloc;
  final SoilsBloc soilsBloc;
  final TaxationCharacteristicBloc taxationCharacteristicBloc;
  final SubjectsRepository subjectsRepository;
  final ProbaInfoRepository probaInfoRepository;
  final TreeInformationRepository treeInformationRepository;
  final TaxationCharacteristicRepository taxationCharacteristicRepository;
}
