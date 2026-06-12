import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taxation_card/core/database/seed_data.dart';
import 'package:taxation_card/core/widgets/species_picker_dialog.dart';
import 'package:taxation_card/features/di/widget/dependencies_scope.dart';
import 'package:taxation_card/features/proba_info/domain/forestry_repository.dart';
import 'package:taxation_card/features/proba_info/domain/proba_info_repository.dart';

final class ProbaInfoScreen extends StatefulWidget {
  const ProbaInfoScreen({super.key, this.initialRecord});

  final ProbaInfoRecord? initialRecord;

  @override
  State<ProbaInfoScreen> createState() => _ProbaInfoScreenState();
}

final class _ProbaInfoScreenState extends State<ProbaInfoScreen> {
  static const _forestTypes = [
    'СБЕЛ',
    'СЛОС',
    'СБР',
    'СВЕР',
    'СЧ',
    'СМОЛ',
    'СД',
    'ССФ',
    'СМБР',
    'СОРЛ',
    'СЛПК',
    'СТР',
    'СМЧ',
    'СОССФ',
    'СЛЛ',
    'СДУБ',
    'СК',
    'СПР',
    'ЕБР',
    'ЕЧ',
    'ЕД',
    'ЕСФ',
    'ЕЛП',
    'ЕЛПК',
    'ЕК',
    'ЕПР',
    'ЕДУБ',
    'ДСН',
    'ДЕЛЛ',
    'ДКЛП',
    'ДПМТ',
    'БОС',
    'ОЛЬШ',
    'ТПМ',
    'СТОС',
    'БТОС',
  ];
  static const _siteClasses = ['1Б', '1А', '1', '2', '3', '4', '5', '5А', '5Б'];
  static const _tluValues = [
    'A0',
    'A1',
    'A2',
    'A3',
    'A4',
    'A5',
    'B0',
    'B1',
    'B2',
    'B3',
    'B4',
    'B5',
    'C0',
    'C1',
    'C2',
    'C3',
    'C4',
    'C5',
    'Д0',
    'Д1',
    'Д2',
    'Д3',
    'Д4',
    'Д5',
    'E0',
    'E1',
    'E2',
    'E3',
    'E4',
    'E5',
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quarterController = TextEditingController();
  final TextEditingController _allotmentController = TextEditingController();
  final TextEditingController _samplePlotNumberController =
      TextEditingController();
  final TextEditingController _samplePlotAreaController =
      TextEditingController();
  final TextEditingController _plantingDateController = TextEditingController();
  final TextEditingController _forestryController = TextEditingController();
  final TextEditingController _subForestryController = TextEditingController();
  final TextEditingController _soilController = TextEditingController();
  final TextEditingController _livingGroundCoverController =
      TextEditingController();
  final TextEditingController _undergrowthController = TextEditingController();
  final TextEditingController _understoryController = TextEditingController();
  final FocusNode _forestryFocusNode = FocusNode();
  final FocusNode _subForestryFocusNode = FocusNode();

  ProbaInfoRecord? _initialRecord;
  List<DistrictForestryRecord> _districtForestries = const [];
  List<SubForestryRecord> _subForestries = const [];
  String? _selectedRegion;
  String? _selectedDistrict;
  String? _selectedSiteClass;
  String? _selectedForestType;
  String? _selectedTlu;
  String? _selectedDominantSpecies;
  var _didLoadForestrySuggestions = false;
  var _isSaving = false;
  var _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    _initialRecord = widget.initialRecord;
    final initialRecord = _initialRecord;
    if (initialRecord != null) {
      _selectedRegion = initialRecord.region;
      _selectedDistrict = initialRecord.district;
      _selectedSiteClass = initialRecord.siteClass;
      _selectedForestType = initialRecord.forestType;
      _selectedTlu = initialRecord.tlu;
      _selectedDominantSpecies = initialRecord.dominantSpecies;
      _syncControllers(initialRecord);
    }

    _quarterController.addListener(_onFormChanged);
    _allotmentController.addListener(_onFormChanged);
    _samplePlotNumberController.addListener(_onFormChanged);
    _samplePlotAreaController.addListener(_onFormChanged);
    _plantingDateController.addListener(_onFormChanged);
    _forestryController.addListener(_onFormChanged);
    _subForestryController.addListener(_onFormChanged);
    _soilController.addListener(_onFormChanged);
    _livingGroundCoverController.addListener(_onFormChanged);
    _undergrowthController.addListener(_onFormChanged);
    _understoryController.addListener(_onFormChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadForestrySuggestions) {
      return;
    }

    _didLoadForestrySuggestions = true;
    unawaited(_loadForestrySuggestions());
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
    _plantingDateController
      ..removeListener(_onFormChanged)
      ..dispose();
    _forestryController
      ..removeListener(_onFormChanged)
      ..dispose();
    _subForestryController
      ..removeListener(_onFormChanged)
      ..dispose();
    _soilController
      ..removeListener(_onFormChanged)
      ..dispose();
    _livingGroundCoverController
      ..removeListener(_onFormChanged)
      ..dispose();
    _undergrowthController
      ..removeListener(_onFormChanged)
      ..dispose();
    _understoryController
      ..removeListener(_onFormChanged)
      ..dispose();
    _forestryFocusNode.dispose();
    _subForestryFocusNode.dispose();
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
        autovalidateMode: _showValidationErrors
            ? AutovalidateMode.always
            : AutovalidateMode.onUserInteraction,
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
                        'Заполните параметры пробной площади.',
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
                      _buildForestDescriptionCard(),
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
    _setControllerText(
      _plantingDateController,
      record.plantingDate == null ? '' : _formatDate(record.plantingDate!),
    );
    _setControllerText(_forestryController, record.forestry ?? '');
    _setControllerText(_subForestryController, record.subForestry ?? '');
    _setControllerText(_soilController, record.soil ?? '');
    _setControllerText(
      _livingGroundCoverController,
      record.livingGroundCover ?? '',
    );
    _setControllerText(_undergrowthController, record.undergrowth ?? '');
    _setControllerText(_understoryController, record.understory ?? '');
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

  Future<void> _loadForestrySuggestions() async {
    try {
      final repository = DependenciesScope.of(context).forestryRepository;
      final districtForestries = await repository.getDistrictForestries();
      final subForestries = await repository.getSubForestries();

      if (!mounted) {
        return;
      }

      setState(() {
        _districtForestries = districtForestries;
        _subForestries = subForestries;
      });
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Не удалось загрузить подсказки лесничеств');
    }
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
                items:
                    _dropdownItemsWithCurrent(
                          russianFederationData.keys,
                          _selectedRegion,
                        )
                        .map(
                          (region) => DropdownMenuItem(
                            value: region,
                            child: Text(
                              region,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (regionValue) {
                  setState(() {
                    _selectedRegion = regionValue;
                    _selectedDistrict = null;
                  });
                },
                validator: _validateRequiredDropdown,
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  '${_selectedRegion ?? ''}-${_selectedDistrict ?? ''}',
                ),
                isExpanded: true,
                initialValue: _selectedDistrict,
                decoration: _inputDecoration(labelText: 'Муниципальный район'),
                items:
                    _dropdownItemsWithCurrent(
                          russianFederationData[_selectedRegion] ?? const [],
                          _selectedDistrict,
                        )
                        .map(
                          (district) => DropdownMenuItem(
                            value: district,
                            child: Text(
                              district,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (districtValue) {
                  setState(() {
                    _selectedDistrict = districtValue;
                  });
                },
                validator: _validateRequiredDropdown,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResponsiveFields(
            children: [
              _buildDateField(
                controller: _plantingDateController,
                labelText: 'Дата закладки',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResponsiveFields(
            children: [
              _buildAutocompleteField(
                controller: _forestryController,
                focusNode: _forestryFocusNode,
                labelText: 'Районное лесничество',
                optionsBuilder: _districtForestryOptions,
                onSelected: (value) {
                  _forestryController.text = value;
                  _subForestryController.clear();
                  _onFormChanged();
                },
              ),
              _buildAutocompleteField(
                controller: _subForestryController,
                focusNode: _subForestryFocusNode,
                labelText: 'Участковое лесничество',
                optionsBuilder: _subForestryOptions,
                onSelected: (value) {
                  _subForestryController.text = value;
                  _onFormChanged();
                },
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
      child: Column(
        children: [
          _buildResponsiveFields(
            children: [
              _buildNumberField(
                controller: _quarterController,
                labelText: 'Квартал',
              ),
              _buildNumberField(
                controller: _allotmentController,
                labelText: 'Выдел',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResponsiveFields(
            children: [
              _buildNumberField(
                controller: _samplePlotNumberController,
                labelText: 'Номер пробной площади',
              ),
              _buildNumberField(
                controller: _samplePlotAreaController,
                labelText: 'Площадь ПП, га',
                allowDecimal: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForestDescriptionCard() {
    return _SectionCard(
      title: 'Лесорастительные условия',
      child: Column(
        children: [
          _buildResponsiveFields(
            children: [
              _buildSpeciesField(
                value: _selectedDominantSpecies,
                labelText: 'Преобладающая порода',
                onTap: _showDominantSpeciesDialog,
              ),
              _buildDropdownField(
                labelText: 'Класс бонитета',
                value: _selectedSiteClass,
                items: _siteClasses,
                onChanged: (value) {
                  setState(() => _selectedSiteClass = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResponsiveFields(
            children: [
              _buildDropdownField(
                labelText: 'Тип леса',
                value: _selectedForestType,
                items: _forestTypes,
                onChanged: (value) {
                  setState(() => _selectedForestType = value);
                },
              ),
              _buildDropdownField(
                labelText: 'ТЛУ',
                value: _selectedTlu,
                items: _tluValues,
                onChanged: (value) {
                  setState(() => _selectedTlu = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResponsiveFields(
            children: [
              _buildTextField(
                controller: _soilController,
                labelText: 'Почва',
                optional: true,
              ),
              _buildTextField(
                controller: _livingGroundCoverController,
                labelText: 'Живой почвенный покров',
                optional: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResponsiveFields(
            children: [
              _buildTextField(
                controller: _undergrowthController,
                labelText: 'Подрост',
                optional: true,
              ),
              _buildTextField(
                controller: _understoryController,
                labelText: 'Подлесок',
                optional: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextFormField _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool optional = false,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(labelText: labelText),
      validator: optional ? null : _validateRequiredText,
    );
  }

  Widget _buildSpeciesField({
    required String? value,
    required String labelText,
    required VoidCallback onTap,
  }) {
    return FormField<String>(
      initialValue: value,
      validator: (_) => _validateRequiredDropdown(_selectedDominantSpecies),
      builder: (field) {
        final selectedValue = _selectedDominantSpecies;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: InputDecorator(
            decoration: _inputDecoration(labelText: labelText).copyWith(
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.search),
            ),
            isEmpty: selectedValue == null || selectedValue.isEmpty,
            child: Text(
              selectedValue ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  TextFormField _buildDateField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: _inputDecoration(
        labelText: labelText,
      ).copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined)),
      validator: _validateRequiredText,
      onTap: () => _selectDate(controller),
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required Iterable<String> Function(String value) optionsBuilder,
    required ValueChanged<String> onSelected,
  }) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (option) => option,
      optionsBuilder: (textEditingValue) =>
          optionsBuilder(textEditingValue.text),
      onSelected: onSelected,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(labelText: labelText),
              validator: _validateRequiredText,
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 520),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);

                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(option, overflow: TextOverflow.ellipsis),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  DropdownButtonFormField<String> _buildDropdownField({
    required String labelText,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _inputDecoration(labelText: labelText),
      items: _dropdownItemsWithCurrent(items, value)
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
      validator: (selectedValue) =>
          selectedValue == null ? 'Выберите значение' : null,
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
    if (_isSaving) {
      return;
    }

    setState(() => _showValidationErrors = true);

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar('Заполните все поля. Пробелы не считаются значением');
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

      _showSnackBar('Данные сохранены');
      Navigator.of(context).pop(true);
    } on FormatException catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Проверьте числовые поля');
    } on Object catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Не удалось сохранить данные');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  ProbaInfoRecord _buildRecord({int? id}) {
    final initialRecord = _initialRecord;

    return ProbaInfoRecord(
      id: id,
      createdAt: initialRecord?.createdAt,
      plantingDate: _tryParseDate(_plantingDateController.text),
      region: _emptyToNull(_selectedRegion),
      district: _emptyToNull(_selectedDistrict),
      forestry: _emptyToNull(_forestryController.text),
      subForestry: _emptyToNull(_subForestryController.text),
      dominantSpecies: _emptyToNull(_selectedDominantSpecies),
      siteClass: _emptyToNull(_selectedSiteClass),
      forestType: _emptyToNull(_selectedForestType),
      tlu: _emptyToNull(_selectedTlu),
      soil: _emptyToNull(_soilController.text),
      livingGroundCover: _emptyToNull(_livingGroundCoverController.text),
      undergrowth: _emptyToNull(_undergrowthController.text),
      understory: _emptyToNull(_understoryController.text),
      quarter: _parseInt(_quarterController.text),
      allotment: _parseInt(_allotmentController.text),
      samplePlotNumber: _parseInt(_samplePlotNumberController.text),
      samplePlotArea: _parseDouble(_samplePlotAreaController.text),
      deadwoodArea: initialRecord?.deadwoodArea ?? 0,
      stumpsAccountingArea: initialRecord?.stumpsAccountingArea ?? 0,
      undergrowthPlotCount: initialRecord?.undergrowthPlotCount ?? 0,
      undergrowthPlotArea: initialRecord?.undergrowthPlotArea ?? 0,
      understoryPlotCount: initialRecord?.understoryPlotCount ?? 0,
      understoryPlotArea: initialRecord?.understoryPlotArea ?? 0,
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
        initialRecord.dominantSpecies !=
            _emptyToNull(_selectedDominantSpecies) ||
        initialRecord.siteClass != _emptyToNull(_selectedSiteClass) ||
        initialRecord.forestType != _emptyToNull(_selectedForestType) ||
        initialRecord.tlu != _emptyToNull(_selectedTlu) ||
        initialRecord.soil != _emptyToNull(_soilController.text) ||
        initialRecord.livingGroundCover !=
            _emptyToNull(_livingGroundCoverController.text) ||
        initialRecord.undergrowth !=
            _emptyToNull(_undergrowthController.text) ||
        initialRecord.understory != _emptyToNull(_understoryController.text) ||
        initialRecord.quarter != _tryParseInt(_quarterController.text) ||
        initialRecord.allotment != _tryParseInt(_allotmentController.text) ||
        initialRecord.samplePlotNumber !=
            _tryParseInt(_samplePlotNumberController.text) ||
        initialRecord.samplePlotArea !=
            _tryParseDouble(_samplePlotAreaController.text) ||
        initialRecord.plantingDate !=
            _tryParseDate(_plantingDateController.text);
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final initialDate = _tryParseDate(controller.text) ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    _setControllerText(controller, _formatDate(selectedDate));
    _onFormChanged();
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

  String? _validateRequiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    return null;
  }

  String? _validateRequiredDropdown(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Выберите значение';
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

  DateTime? _tryParseDate(String value) {
    final parts = value.trim().split('.');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
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

  List<String> _dropdownItemsWithCurrent(
    Iterable<String> items,
    String? currentValue,
  ) {
    final values = items.toList();
    final current = _emptyToNull(currentValue);
    if (current == null || values.contains(current)) {
      return values;
    }

    return [current, ...values];
  }

  Iterable<String> _districtForestryOptions(String value) {
    return _filterUniqueOptions(
      _districtForestries.map((forestry) => forestry.name),
      value,
    );
  }

  Iterable<String> _subForestryOptions(String value) {
    final districtForestryName = _forestryController.text.trim();
    final districtForestryCodes = _districtForestries
        .where((forestry) => forestry.name == districtForestryName)
        .map((forestry) => forestry.fgisCode)
        .toSet();

    final options = districtForestryCodes.isEmpty
        ? _subForestries.map((forestry) => forestry.name)
        : _subForestries
              .where(
                (forestry) => districtForestryCodes.contains(
                  forestry.districtForestryCode,
                ),
              )
              .map((forestry) => forestry.name);

    return _filterUniqueOptions(options, value);
  }

  Future<void> _showDominantSpeciesDialog() async {
    final result = await showSpeciesPickerDialog(
      context: context,
      selectedSpecies: _selectedDominantSpecies,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _selectedDominantSpecies = result);
    _formKey.currentState?.validate();
    _onFormChanged();
  }

  Iterable<String> _filterUniqueOptions(
    Iterable<String> options,
    String value,
  ) {
    final query = value.trim().toLowerCase();
    final result = <String>[];
    final seen = <String>{};

    for (final option in options) {
      final normalizedOption = option.toLowerCase();
      if (query.isNotEmpty && !normalizedOption.contains(query)) {
        continue;
      }

      if (!seen.add(option)) {
        continue;
      }

      result.add(option);
      if (result.length >= 20) {
        break;
      }
    }

    return result;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
