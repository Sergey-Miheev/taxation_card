import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/features/taxation_characteristic/bloc/taxation_characteristic_bloc.dart';

final class TaxationCharacteristicScreen extends StatefulWidget {
  const TaxationCharacteristicScreen({super.key});

  @override
  State<TaxationCharacteristicScreen> createState() =>
      _TaxationCharacteristicScreenState();
}

final class _TaxationCharacteristicScreenState
    extends State<TaxationCharacteristicScreen>
    with AutomaticKeepAliveClientMixin {
  static const _tiers = ['1', '2', '3'];
  static const _forestTypes = [
    'Черничный',
    'Кисличный',
    'Мшистый',
    'Травяной',
    'Сфагновый',
  ];
  static const _siteClasses = ['Ia', 'I', 'II', 'III', 'IV', 'V'];
  static const _merchantabilityClasses = ['1', '2', '3', '4'];

  final _formKey = GlobalKey<FormState>();
  final _dominantSpeciesController = TextEditingController();
  final _compositionCoefficientController = TextEditingController();
  final _ageController = TextEditingController();
  final _averageHeightController = TextEditingController();
  final _diameterController = TextEditingController();
  final _densityController = TextEditingController();
  final _stockController = TextEditingController();
  final _tluController = TextEditingController();
  final _plantationsTotalController = TextEditingController();
  final _coniferousTotalController = TextEditingController();
  final _canopyClosureController = TextEditingController();
  final _sparsenessController = TextEditingController();
  final _commercialWoodOutputController = TextEditingController();

  late final TaxationCharacteristicBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<TaxationCharacteristicBloc>();
    _syncControllers(_bloc.state);
    _dominantSpeciesController.addListener(_onDominantSpeciesChanged);
    _compositionCoefficientController.addListener(
      _onCompositionCoefficientChanged,
    );
    _ageController.addListener(_onAgeChanged);
    _averageHeightController.addListener(_onAverageHeightChanged);
    _diameterController.addListener(_onDiameterChanged);
    _densityController.addListener(_onDensityChanged);
    _stockController.addListener(_onStockChanged);
    _tluController.addListener(_onTluChanged);
    _plantationsTotalController.addListener(_onPlantationsTotalChanged);
    _coniferousTotalController.addListener(_onConiferousTotalChanged);
    _canopyClosureController.addListener(_onCanopyClosureChanged);
    _sparsenessController.addListener(_onSparsenessChanged);
    _commercialWoodOutputController.addListener(_onCommercialWoodOutputChanged);
  }

  @override
  void dispose() {
    _dominantSpeciesController
      ..removeListener(_onDominantSpeciesChanged)
      ..dispose();
    _compositionCoefficientController
      ..removeListener(_onCompositionCoefficientChanged)
      ..dispose();
    _ageController
      ..removeListener(_onAgeChanged)
      ..dispose();
    _averageHeightController
      ..removeListener(_onAverageHeightChanged)
      ..dispose();
    _diameterController
      ..removeListener(_onDiameterChanged)
      ..dispose();
    _densityController
      ..removeListener(_onDensityChanged)
      ..dispose();
    _stockController
      ..removeListener(_onStockChanged)
      ..dispose();
    _tluController
      ..removeListener(_onTluChanged)
      ..dispose();
    _plantationsTotalController
      ..removeListener(_onPlantationsTotalChanged)
      ..dispose();
    _coniferousTotalController
      ..removeListener(_onConiferousTotalChanged)
      ..dispose();
    _canopyClosureController
      ..removeListener(_onCanopyClosureChanged)
      ..dispose();
    _sparsenessController
      ..removeListener(_onSparsenessChanged)
      ..dispose();
    _commercialWoodOutputController
      ..removeListener(_onCommercialWoodOutputChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return BlocListener<
      TaxationCharacteristicBloc,
      TaxationCharacteristicState
    >(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == TaxationCharacteristicStatus.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Данные сохранены')));
        }

        if (state.status == TaxationCharacteristicStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Не удалось сохранить данные'),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Добавление таксационной записи')),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child:
                BlocBuilder<
                  TaxationCharacteristicBloc,
                  TaxationCharacteristicState
                >(
                  buildWhen: (previous, current) =>
                      previous.status != current.status,
                  builder: (context, state) {
                    final isLoading =
                        state.status == TaxationCharacteristicStatus.loading;

                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : _onSavePressed,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                            ),
                            child: const Text('Сохранить'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: isLoading ? null : _onAddPressed,
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: const Text('Добавить'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Добавление таксационной записи',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Общие характеристики',
                  children: [
                    BlocBuilder<
                      TaxationCharacteristicBloc,
                      TaxationCharacteristicState
                    >(
                      buildWhen: (previous, current) =>
                          previous.tier != current.tier,
                      builder: (context, state) {
                        return _buildDropdownField(
                          labelText: 'Ярус',
                          value: state.tier,
                          items: _tiers,
                          onChanged: (value) => _onDropdownChanged(
                            TaxationCharacteristicField.tier,
                            value,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _dominantSpeciesController,
                      labelText: 'Преобладающая порода',
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _compositionCoefficientController,
                      labelText: 'Коэффициент состава',
                      allowDecimal: true,
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _ageController,
                      labelText: 'Возраст',
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<
                      TaxationCharacteristicBloc,
                      TaxationCharacteristicState
                    >(
                      buildWhen: (previous, current) =>
                          previous.forestType != current.forestType,
                      builder: (context, state) {
                        return _buildDropdownField(
                          labelText: 'Тип леса',
                          value: state.forestType,
                          items: _forestTypes,
                          onChanged: (value) => _onDropdownChanged(
                            TaxationCharacteristicField.forestType,
                            value,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<
                      TaxationCharacteristicBloc,
                      TaxationCharacteristicState
                    >(
                      buildWhen: (previous, current) =>
                          previous.siteClass != current.siteClass,
                      builder: (context, state) {
                        return _buildDropdownField(
                          labelText: 'Класс бонитета',
                          value: state.siteClass,
                          items: _siteClasses,
                          onChanged: (value) => _onDropdownChanged(
                            TaxationCharacteristicField.siteClass,
                            value,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _tluController,
                      labelText: 'ТЛУ',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Таксационные показатели',
                  children: [
                    _buildNumberField(
                      controller: _averageHeightController,
                      labelText: 'Средняя высота, м',
                      allowDecimal: true,
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _diameterController,
                      labelText: 'Диаметр, см',
                      allowDecimal: true,
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _densityController,
                      labelText: 'Полнота',
                      allowDecimal: true,
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _canopyClosureController,
                      labelText: 'Сомкнутость',
                      allowDecimal: true,
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _sparsenessController,
                      labelText: 'Изреженность',
                      allowDecimal: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Запасы и структура',
                  children: [
                    _buildNumberField(
                      controller: _stockController,
                      labelText: 'Запас, м³',
                      allowDecimal: true,
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _plantationsTotalController,
                      labelText: 'Лесные насаждения: Всего',
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _coniferousTotalController,
                      labelText: 'В том числе хвойных',
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _commercialWoodOutputController,
                      labelText: '% выхода деловой древесины',
                      allowDecimal: true,
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<
                      TaxationCharacteristicBloc,
                      TaxationCharacteristicState
                    >(
                      buildWhen: (previous, current) =>
                          previous.merchantabilityClass !=
                          current.merchantabilityClass,
                      builder: (context, state) {
                        return _buildDropdownField(
                          labelText: 'Класс товарности',
                          value: state.merchantabilityClass,
                          items: _merchantabilityClasses,
                          onChanged: (value) => _onDropdownChanged(
                            TaxationCharacteristicField.merchantabilityClass,
                            value,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  DropdownButtonFormField<String> _buildDropdownField({
    required String labelText,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _inputDecoration(labelText),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
      validator: (selectedValue) =>
          selectedValue == null ? 'Выберите значение' : null,
    );
  }

  TextFormField _buildTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(labelText),
      validator: _validateRequiredText,
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
      decoration: _inputDecoration(labelText),
      validator: _validatePositiveNumber,
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  String? _validateRequiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    return null;
  }

  String? _validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    final parsedValue = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsedValue == null) {
      return 'Введите корректное число';
    }

    if (parsedValue <= 0) {
      return 'Значение должно быть больше 0';
    }

    return null;
  }

  void _syncControllers(TaxationCharacteristicState state) {
    _dominantSpeciesController.text = state.dominantSpecies;
    _compositionCoefficientController.text = state.compositionCoefficient;
    _ageController.text = state.age;
    _averageHeightController.text = state.averageHeight;
    _diameterController.text = state.diameter;
    _densityController.text = state.density;
    _stockController.text = state.stock;
    _tluController.text = state.tlu;
    _plantationsTotalController.text = state.plantationsTotal;
    _coniferousTotalController.text = state.coniferousTotal;
    _canopyClosureController.text = state.canopyClosure;
    _sparsenessController.text = state.sparseness;
    _commercialWoodOutputController.text = state.commercialWoodOutput;
  }

  void _onDropdownChanged(TaxationCharacteristicField field, String? value) {
    if (value == null) {
      return;
    }

    _bloc.add(
      TaxationCharacteristicEvent.fieldChanged(field: field, value: value),
    );
  }

  void _onDominantSpeciesChanged() {
    _onTextChanged(
      TaxationCharacteristicField.dominantSpecies,
      _dominantSpeciesController.text,
    );
  }

  void _onCompositionCoefficientChanged() {
    _onTextChanged(
      TaxationCharacteristicField.compositionCoefficient,
      _compositionCoefficientController.text,
    );
  }

  void _onAgeChanged() {
    _onTextChanged(TaxationCharacteristicField.age, _ageController.text);
  }

  void _onAverageHeightChanged() {
    _onTextChanged(
      TaxationCharacteristicField.averageHeight,
      _averageHeightController.text,
    );
  }

  void _onDiameterChanged() {
    _onTextChanged(
      TaxationCharacteristicField.diameter,
      _diameterController.text,
    );
  }

  void _onDensityChanged() {
    _onTextChanged(
      TaxationCharacteristicField.density,
      _densityController.text,
    );
  }

  void _onStockChanged() {
    _onTextChanged(TaxationCharacteristicField.stock, _stockController.text);
  }

  void _onTluChanged() {
    _onTextChanged(TaxationCharacteristicField.tlu, _tluController.text);
  }

  void _onPlantationsTotalChanged() {
    _onTextChanged(
      TaxationCharacteristicField.plantationsTotal,
      _plantationsTotalController.text,
    );
  }

  void _onConiferousTotalChanged() {
    _onTextChanged(
      TaxationCharacteristicField.coniferousTotal,
      _coniferousTotalController.text,
    );
  }

  void _onCanopyClosureChanged() {
    _onTextChanged(
      TaxationCharacteristicField.canopyClosure,
      _canopyClosureController.text,
    );
  }

  void _onSparsenessChanged() {
    _onTextChanged(
      TaxationCharacteristicField.sparseness,
      _sparsenessController.text,
    );
  }

  void _onCommercialWoodOutputChanged() {
    _onTextChanged(
      TaxationCharacteristicField.commercialWoodOutput,
      _commercialWoodOutputController.text,
    );
  }

  void _onTextChanged(TaxationCharacteristicField field, String value) {
    _bloc.add(
      TaxationCharacteristicEvent.fieldChanged(field: field, value: value),
    );
  }

  void _onAddPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      _bloc.add(const TaxationCharacteristicEvent.added());
    }
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      _bloc.add(const TaxationCharacteristicEvent.saved());
    }
  }
}

final class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
