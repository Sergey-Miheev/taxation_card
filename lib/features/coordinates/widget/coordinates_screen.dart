import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';

final class CoordinatesScreen extends StatefulWidget {
  const CoordinatesScreen({required this.probaInfoId, super.key});

  final int probaInfoId;

  @override
  State<CoordinatesScreen> createState() => _CoordinatesScreenState();
}

final class _CoordinatesScreenState extends State<CoordinatesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _xControllers = List.generate(4, (_) => TextEditingController());
  final _yControllers = List.generate(4, (_) => TextEditingController());

  var _selectedPoint = 0;
  var _isLoading = true;
  var _isSaving = false;
  var _isGettingGps = false;
  var _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCoordinates());
  }

  @override
  void dispose() {
    for (final controller in [..._xControllers, ..._yControllers]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Координаты пробной площади')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              autovalidateMode: _showValidationErrors
                  ? AutovalidateMode.always
                  : AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: _CoordinateSquare(
                            selectedPoint: _selectedPoint,
                            onPointSelected: (point) {
                              setState(() => _selectedPoint = point);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Точка ${_selectedPoint + 1}',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                _buildCoordinateFields(_selectedPoint),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isGettingGps
                                        ? null
                                        : _fillSelectedPointFromGps,
                                    icon: _isGettingGps
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.my_location),
                                    label: const Text('Получить из GPS'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSaving ? null : _saveCoordinates,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: _isSaving
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('Сохранить точку ${_selectedPoint + 1}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCoordinateFields(int pointIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final fields = [
          TextFormField(
            controller: _xControllers[pointIndex],
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('x${pointIndex + 1} — широта'),
            validator: _validateRequiredText,
          ),
          TextFormField(
            controller: _yControllers[pointIndex],
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('y${pointIndex + 1} — долгота'),
            validator: _validateRequiredText,
          ),
        ];

        if (!isWide) {
          return Column(
            children: [fields[0], const SizedBox(height: 12), fields[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 12),
            Expanded(child: fields[1]),
          ],
        );
      },
    );
  }

  Future<void> _loadCoordinates() async {
    try {
      final record = await DependenciesScope.of(
        context,
      ).probaInfoRepository.getById(widget.probaInfoId);

      if (!mounted) {
        return;
      }

      if (record == null) {
        _showSnackBar('Пробная площадь не найдена');
        Navigator.of(context).pop();
        return;
      }

      _setText(_xControllers[0], record.x1 ?? '');
      _setText(_yControllers[0], record.y1 ?? '');
      _setText(_xControllers[1], record.x2 ?? '');
      _setText(_yControllers[1], record.y2 ?? '');
      _setText(_xControllers[2], record.x3 ?? '');
      _setText(_yControllers[2], record.y3 ?? '');
      _setText(_xControllers[3], record.x4 ?? '');
      _setText(_yControllers[3], record.y4 ?? '');
    } on Object catch (_) {
      if (mounted) {
        _showSnackBar('Не удалось загрузить координаты');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCoordinates() async {
    if (_isSaving) {
      return;
    }

    setState(() => _showValidationErrors = true);

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar('Заполните выделенные поля');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DependenciesScope.of(
        context,
      ).probaInfoRepository.updateCoordinatePoint(
        id: widget.probaInfoId,
        pointNumber: _selectedPoint + 1,
        x: _xControllers[_selectedPoint].text.trim(),
        y: _yControllers[_selectedPoint].text.trim(),
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('Точка ${_selectedPoint + 1} сохранена');
    } on Object catch (_) {
      if (mounted) {
        _showSnackBar('Не удалось сохранить точку ${_selectedPoint + 1}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _fillSelectedPointFromGps() async {
    if (_isGettingGps) {
      return;
    }

    setState(() => _isGettingGps = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Включите геолокацию на устройстве');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showSnackBar('Разрешите доступ к геолокации');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Доступ к геолокации запрещён в настройках');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) {
        return;
      }

      _setText(
        _xControllers[_selectedPoint],
        position.latitude.toStringAsFixed(7),
      );
      _setText(
        _yControllers[_selectedPoint],
        position.longitude.toStringAsFixed(7),
      );
      setState(() {});
      _showSnackBar('Координаты подставлены для точки ${_selectedPoint + 1}');
    } on TimeoutException catch (_) {
      Position? lastKnownPosition;
      try {
        lastKnownPosition = await Geolocator.getLastKnownPosition();
      } on Object {
        lastKnownPosition = null;
      }

      if (!mounted) {
        return;
      }

      if (lastKnownPosition == null) {
        _showSnackBar('GPS не ответил. Последняя позиция не найдена');
        return;
      }

      _setText(
        _xControllers[_selectedPoint],
        lastKnownPosition.latitude.toStringAsFixed(7),
      );
      _setText(
        _yControllers[_selectedPoint],
        lastKnownPosition.longitude.toStringAsFixed(7),
      );
      setState(() {});
      _showSnackBar(
        'Подставлена последняя известная позиция для точки ${_selectedPoint + 1}',
      );
    } on Object catch (_) {
      if (mounted) {
        _showSnackBar('Не удалось получить координаты GPS');
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingGps = false);
      }
    }
  }

  void _setText(TextEditingController controller, String text) {
    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  String? _validateRequiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    return null;
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _CoordinateSquare extends StatelessWidget {
  const _CoordinateSquare({
    required this.selectedPoint,
    required this.onPointSelected,
  });

  final int selectedPoint;
  final ValueChanged<int> onPointSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          _buildPointButton(context, point: 0, alignment: Alignment.bottomLeft),
          _buildPointButton(context, point: 1, alignment: Alignment.topLeft),
          _buildPointButton(context, point: 2, alignment: Alignment.topRight),
          _buildPointButton(
            context,
            point: 3,
            alignment: Alignment.bottomRight,
          ),
        ],
      ),
    );
  }

  Widget _buildPointButton(
    BuildContext context, {
    required int point,
    required Alignment alignment,
  }) {
    final isSelected = point == selectedPoint;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox.square(
          dimension: 64,
          child: isSelected
              ? FilledButton(
                  onPressed: () => onPointSelected(point),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: Text(
                    '${point + 1}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: () => onPointSelected(point),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: Text(
                    '${point + 1}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
