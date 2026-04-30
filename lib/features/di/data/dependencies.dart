import 'package:taxation_card/features/main_info/bloc/main_info_bloc.dart';
import 'package:taxation_card/features/permanent_PP/bloc/permanent_pp_bloc.dart';
import 'package:taxation_card/features/permanent_PP/domain/subjects_repository.dart';

final class Dependencies {
  const Dependencies({
    required this.mainInfoBloc,
    required this.permanentPpBloc,
    required this.subjectsRepository,
  });

  final MainInfoBloc mainInfoBloc;
  final PermanentPpBloc permanentPpBloc;
  final SubjectsRepository subjectsRepository;
}
