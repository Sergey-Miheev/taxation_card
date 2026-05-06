import 'package:flutter/material.dart';
import 'package:taxation_card/core/database/seed_data.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/proba_info/domain/proba_info_repository.dart';

final class ProbaInfoScreen extends StatefulWidget {
  const ProbaInfoScreen({super.key, this.initialRecord});

  final ProbaInfoRecord? initialRecord;

  @override
  State<ProbaInfoScreen> createState() => _ProbaInfoScreenState();
}

final class _ProbaInfoScreenState extends State<ProbaInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quarterController = TextEditingController();
  final TextEditingController _allotmentController = TextEditingController();
  final TextEditingController _samplePlotNumberController =
      TextEditingController();
  final TextEditingController _samplePlotAreaController =
      TextEditingController();
  final TextEditingController _forestryController = TextEditingController();
  final TextEditingController _subForestryController = TextEditingController();

  ProbaInfoRecord? _initialRecord;
  String? _selectedRegion;
  String? _selectedDistrict;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialRecord = widget.initialRecord;
    final initialRecord = _initialRecord;
    if (initialRecord != null) {
      _selectedRegion = initialRecord.region;
      _selectedDistrict = initialRecord.district;
      _syncControllers(initialRecord);
    }

    _quarterController.addListener(_onFormChanged);
    _allotmentController.addListener(_onFormChanged);
    _samplePlotNumberController.addListener(_onFormChanged);
    _samplePlotAreaController.addListener(_onFormChanged);
    _forestryController.addListener(_onFormChanged);
    _subForestryController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _quarterController
      ..removeListener(_onFormChanged)
      ..dispose();
    _allotmentController
      ..removeListener(_onFormChanged)
      ..dispose();
    _samplePlotNumberController
      ..removeListener(_onFormChanged)
      ..dispose();
    _samplePlotAreaController
      ..removeListener(_onFormChanged)
      ..dispose();
    _forestryController
      ..removeListener(_onFormChanged)
      ..dispose();
    _subForestryController
      ..removeListener(_onFormChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _initialRecord != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Редактирование пробной площади'
              : 'Информация о пробной площади',
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 720;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Общая информация',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Заполните местоположение и параметры пробной площади.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      if (isTablet)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildLocationCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSamplePlotCard()),
                          ],
                        )
                      else ...[
                        _buildLocationCard(),
                        const SizedBox(height: 12),
                        _buildSamplePlotCard(),
                      ],
                      const SizedBox(height: 16),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _syncControllers(ProbaInfoRecord record) {
    _setControllerText(_quarterController, record.quarter.toString());
    _setControllerText(_allotmentController, record.allotment.toString());
    _setControllerText(
      _samplePlotNumberController,
      record.samplePlotNumber.toString(),
    );
    _setControllerText(
      _samplePlotAreaController,
      _formatDouble(record.samplePlotArea),
    );
    _setControllerText(_forestryController, record.forestry ?? '');
    _setControllerText(_subForestryController, record.subForestry ?? '');
  }

  void _setControllerText(TextEditingController controller, String text) {
    if (controller.text == text) {
      return;
    }

    controller.value = controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
    );
  }

  void _onFormChanged() {
    if (_initialRecord == null) {
      return;
    }

    setState(() {});
  }

  Widget _buildLocationCard() {
    return _SectionCard(
      title: 'Местоположение',
      child: Column(
        children: [
          _buildResponsiveFields(
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedRegion),
                isExpanded: true,
                initialValue: _selectedRegion,
                decoration: _inputDecoration(labelText: 'Субъект РФ'),
                items: russianFederationData.keys
                    .map(
                      (region) => DropdownMenuItem(
                        value: region,
                        child: Text(region, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (regionValue) {
                  setState(() {
                    _selectedRegion = regionValue;
                    _selectedDistrict = null;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  '${_selectedRegion ?? ''}-${_selectedDistrict ?? ''}',
                ),
                isExpanded: true,
                initialValue: _selectedDistrict,
                decoration: _inputDecoration(labelText: 'Муниципальный район'),
                items: russianFederationData[_selectedRegion]
                    ?.map(
                      (district) => DropdownMenuItem(
                        value: district,
                        child: Text(district, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (districtValue) {
                  setState(() {
                    _selectedDistrict = districtValue;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResponsiveFields(
            children: [
              TextFormField(
                controller: _forestryController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(labelText: 'Районное лесничество'),
              ),
              TextFormField(
                controller: _subForestryController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  labelText: 'Участковое лесничество',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSamplePlotCard() {
    return _SectionCard(
      title: 'Пробная площадь',
      child: _buildResponsiveFields(
        children: [
          _buildNumberField(
            controller: _quarterController,
            labelText: 'Квартал',
          ),
          _buildNumberField(
            controller: _allotmentController,
            labelText: 'Выдел',
          ),
          _buildNumberField(
            controller: _samplePlotNumberController,
            labelText: 'Номер пробной площади',
          ),
          _buildNumberField(
            controller: _samplePlotAreaController,
            labelText: 'Площадь ПП',
            allowDecimal: true,
          ),
        ],
      ),
    );
  }

  TextFormField _buildNumberField({
    required TextEditingController controller,
    required String labelText,
    bool allowDecimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(labelText: labelText),
      validator: allowDecimal ? _validatePositiveNumber : _validatePositiveInt,
    );
  }

  Widget _buildSaveButton() {
    final canSave =
        !_isSaving && (_initialRecord == null || _isChangedFromInitial());

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canSave ? _saveProbaInfo : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Сохранить'),
      ),
    );
  }

  Future<void> _saveProbaInfo() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = DependenciesScope.of(context).probaInfoRepository;
      final initialRecord = _initialRecord;
      final record = _buildRecord(id: initialRecord?.id);

      if (initialRecord == null) {
        await repository.insert(record);
      } else {
        await repository.update(record);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Данные сохранены')));
      Navigator.of(context).pop(true);
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить данные')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  ProbaInfoRecord _buildRecord({int? id}) {
    return ProbaInfoRecord(
      id: id,
      region: _emptyToNull(_selectedRegion),
      district: _emptyToNull(_selectedDistrict),
      forestry: _emptyToNull(_forestryController.text),
      subForestry: _emptyToNull(_subForestryController.text),
      quarter: _parseInt(_quarterController.text),
      allotment: _parseInt(_allotmentController.text),
      samplePlotNumber: _parseInt(_samplePlotNumberController.text),
      samplePlotArea: _parseDouble(_samplePlotAreaController.text),
    );
  }

  bool _isChangedFromInitial() {
    final initialRecord = _initialRecord;
    if (initialRecord == null) {
      return true;
    }

    return initialRecord.region != _emptyToNull(_selectedRegion) ||
        initialRecord.district != _emptyToNull(_selectedDistrict) ||
        initialRecord.forestry != _emptyToNull(_forestryController.text) ||
        initialRecord.subForestry !=
            _emptyToNull(_subForestryController.text) ||
        initialRecord.quarter != _tryParseInt(_quarterController.text) ||
        initialRecord.allotment != _tryParseInt(_allotmentController.text) ||
        initialRecord.samplePlotNumber !=
            _tryParseInt(_samplePlotNumberController.text) ||
        initialRecord.samplePlotArea !=
            _tryParseDouble(_samplePlotAreaController.text);
  }

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    final parsedValue = _tryParseDouble(value);
    if (parsedValue == null) {
      return 'Введите корректное число';
    }

    if (parsedValue <= 0) {
      return 'Значение должно быть больше 0';
    }

    return null;
  }

  String? _validatePositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    final parsedValue = _tryParseInt(value);
    if (parsedValue == null) {
      return 'Введите целое число';
    }

    if (parsedValue <= 0) {
      return 'Значение должно быть больше 0';
    }

    return null;
  }

  int _parseInt(String value) {
    return int.parse(value.trim());
  }

  int? _tryParseInt(String value) {
    return int.tryParse(value.trim());
  }

  double _parseDouble(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }

  double? _tryParseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _formatDouble(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildResponsiveFields({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        if (!isWide) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
