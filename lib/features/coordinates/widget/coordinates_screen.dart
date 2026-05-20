import 'dart:async';

import 'package:flutter/material.dart';
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
                                : const Text('Сохранить координаты'),
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

    final firstEmptyPoint = _firstEmptyPointIndex();
    if (firstEmptyPoint != null) {
      setState(() => _selectedPoint = firstEmptyPoint);
      _showSnackBar('Заполните координаты всех точек');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar('Заполните выделенные поля');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DependenciesScope.of(context).probaInfoRepository.updateCoordinates(
        id: widget.probaInfoId,
        x1: _xControllers[0].text.trim(),
        y1: _yControllers[0].text.trim(),
        x2: _xControllers[1].text.trim(),
        y2: _yControllers[1].text.trim(),
        x3: _xControllers[2].text.trim(),
        y3: _yControllers[2].text.trim(),
        x4: _xControllers[3].text.trim(),
        y4: _yControllers[3].text.trim(),
      );

      if (!mounted) {
        return;
      }

      _showSnackBar('Координаты сохранены');
      Navigator.of(context).pop();
    } on Object catch (_) {
      if (mounted) {
        _showSnackBar('Не удалось сохранить координаты');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  int? _firstEmptyPointIndex() {
    for (var i = 0; i < 4; i++) {
      if (_xControllers[i].text.trim().isEmpty ||
          _yControllers[i].text.trim().isEmpty) {
        return i;
      }
    }

    return null;
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
