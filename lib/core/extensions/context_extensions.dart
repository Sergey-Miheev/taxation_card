import 'package:flutter/material.dart';
import 'package:taxation_card/features/di/data/dependencies.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';

extension ContextExtensions on BuildContext {
  T? inhMaybeOf<T extends InheritedWidget>({bool listen = true}) => listen
      ? dependOnInheritedWidgetOfExactType<T>()
      : getInheritedWidgetOfExactType<T>();

  T inhOf<T extends InheritedWidget>({bool listen = true}) =>
      inhMaybeOf(listen: listen) ??
      (throw ArgumentError(
        'Out of scope, not found inherited widget a $T of the exact type',
        'out_of_scope',
      ));

  Dependencies get dependencies => DependenciesScope.of(this);

  ThemeData get theme => Theme.of(this);

  TextTheme get textStyles => theme.textTheme;
}
