import 'package:flutter/widgets.dart';
import 'package:taxation_card/features/di/data/dependencies.dart';

final class DependenciesScope extends InheritedWidget {
  const DependenciesScope({
    required this.dependencies,
    required super.child,
    super.key,
  });

  final Dependencies dependencies;

  static Dependencies of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DependenciesScope>();
    if (scope == null) {
      throw ArgumentError(
        'Out of scope, not found inherited widget a DependenciesScope of the exact type',
        'out_of_scope',
      );
    }
    return scope.dependencies;
  }

  @override
  bool updateShouldNotify(covariant DependenciesScope oldWidget) =>
      oldWidget.dependencies != dependencies;
}
