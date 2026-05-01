import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxation_card/features/main_info/bloc/main_info_bloc.dart';
import 'package:taxation_card/features/permanent_PP/bloc/permanent_pp_bloc.dart';

final class PermanentPpScreen extends StatefulWidget {
  const PermanentPpScreen({super.key});

  @override
  State<PermanentPpScreen> createState() => _PermanentPpScreenState();
}

final class _PermanentPpScreenState extends State<PermanentPpScreen>
    with AutomaticKeepAliveClientMixin {
  static const _landCategories = [
    'Земли лесного фонда',
    'Земли особо охраняемых территорий',
    'Земли сельскохозяйственного назначения',
  ];
  static const _forestryTypes = ['Защитное', 'Эксплуатационное', 'Резервное'];
  static const _ozuOptions = [
    'Отсутствует',
    'Водоохранная зона',
    'Прибрежная защитная полоса',
    'Особо защитный участок',
  ];
  static const _slopeExposures = [
    'Северная',
    'Северо-восточная',
    'Восточная',
    'Юго-восточная',
    'Южная',
    'Юго-западная',
    'Западная',
    'Северо-западная',
    'Ровная поверхность',
  ];
  static const _erosionOptions = ['Нет', 'Есть'];
  static const _erosionTypes = [
    'Не определяется',
    'Водная',
    'Ветровая',
    'Смешанная',
  ];
  static const _erosionDegrees = [
    'Не определяется',
    'Слабая',
    'Средняя',
    'Сильная',
  ];
  static const _speciesOptions = [
    'Сосна',
    'Ель',
    'Береза',
    'Осина',
    'Лиственница',
  ];
  static const _siteClassOptions = ['Ia', 'I', 'II', 'III', 'IV', 'V'];
  static const _forestTypeOptions = [
    'Черничный',
    'Кисличный',
    'Мшистый',
    'Травяной',
  ];
  static const _tluOptions = ['А1', 'А2', 'В2', 'С2', 'С3'];
  static const _cuttingTypeOptions = [
    'Сплошная',
    'Постепенная',
    'Выборочная',
    'Санитарная',
  ];

  final _formKey = GlobalKey<FormState>();
  final _plotNumberController = TextEditingController();
  final _plotAreaController = TextEditingController();
  final _heightController = TextEditingController();
  final _slopeAngleController = TextEditingController();
  final _cuttingYearController = TextEditingController();
  final _stumpsTotalController = TextEditingController();
  final _stumpsPineController = TextEditingController();
  final _stumpDiameterController = TextEditingController();

  String? _selectedLandCategory;
  String? _selectedForestryType;
  String? _selectedOzu;
  String? _selectedSlopeExposure;
  String? _selectedErosion;
  String? _selectedErosionType;
  String? _selectedErosionDegree;
  String? _selectedSpecies;
  String? _selectedSiteClass;
  String? _selectedForestType;
  String? _selectedTlu;
  String? _selectedCuttingType;

  @override
  void dispose() {
    _plotNumberController.dispose();
    _plotAreaController.dispose();
    _heightController.dispose();
    _slopeAngleController.dispose();
    _cuttingYearController.dispose();
    _stumpsTotalController.dispose();
    _stumpsPineController.dispose();
    _stumpDiameterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return BlocListener<PermanentPpBloc, PermanentPpState>(
      listener: (context, state) {
        state.whenOrNull(
          success: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Данные сохранены.')));
          },
          failure: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message ?? 'Не удалось сохранить данные.'),
              ),
            );
          },
        );
      },
      child: Scaffold(
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: BlocBuilder<PermanentPpBloc, PermanentPpState>(
              builder: (context, state) {
                final isLoading = state.maybeWhen(
                  loading: () => true,
                  orElse: () => false,
                );

                return ElevatedButton(
                  onPressed: isLoading ? null : _onSavePressed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Сохранить'),
                );
              },
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Постоянная ПП', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Заполните параметры участка и лесные характеристики. Все поля доступны для редактирования на мобильном устройстве.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                const _MainInfoSummary(),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Основная информация',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          controller: _plotNumberController,
                          labelText: 'Номер выдела',
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          controller: _plotAreaController,
                          labelText: 'Площадь выдела, га',
                          allowDecimal: true,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'Категория земель',
                          value: _selectedLandCategory,
                          items: _landCategories,
                          onChanged: (value) {
                            setState(() => _selectedLandCategory = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'Хозяйство',
                          value: _selectedForestryType,
                          items: _forestryTypes,
                          onChanged: (value) {
                            setState(() => _selectedForestryType = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'ОЗУ',
                          value: _selectedOzu,
                          items: _ozuOptions,
                          onChanged: (value) {
                            setState(() => _selectedOzu = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          controller: _heightController,
                          labelText: 'Н, у.м.',
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'Экспозиция склона',
                          value: _selectedSlopeExposure,
                          items: _slopeExposures,
                          onChanged: (value) {
                            setState(() => _selectedSlopeExposure = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          controller: _slopeAngleController,
                          labelText: 'Угол наклона',
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'Эрозия',
                          value: _selectedErosion,
                          items: _erosionOptions,
                          onChanged: (value) {
                            setState(() => _selectedErosion = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'Вид эрозии',
                          value: _selectedErosionType,
                          items: _erosionTypes,
                          onChanged: (value) {
                            setState(() => _selectedErosionType = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'Степень эрозии',
                          value: _selectedErosionDegree,
                          items: _erosionDegrees,
                          onChanged: (value) {
                            setState(() => _selectedErosionDegree = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Лесные характеристики',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'Преобладающая порода',
                          value: _selectedSpecies,
                          items: _speciesOptions,
                          onChanged: (value) {
                            setState(() => _selectedSpecies = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'Класс бонитета',
                          value: _selectedSiteClass,
                          items: _siteClassOptions,
                          onChanged: (value) {
                            setState(() => _selectedSiteClass = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'Тип леса',
                          value: _selectedForestType,
                          items: _forestTypeOptions,
                          onChanged: (value) {
                            setState(() => _selectedForestType = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'ТЛУ',
                          value: _selectedTlu,
                          items: _tluOptions,
                          onChanged: (value) {
                            setState(() => _selectedTlu = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          controller: _cuttingYearController,
                          labelText: 'Год рубки',
                        ),
                        const SizedBox(height: 16),
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Пни, шт/га',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          child: Column(
                            children: [
                              _buildNumberField(
                                controller: _stumpsTotalController,
                                labelText: 'Всего',
                              ),
                              const SizedBox(height: 16),
                              _buildNumberField(
                                controller: _stumpsPineController,
                                labelText: 'Сосны',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildNumberField(
                          controller: _stumpDiameterController,
                          labelText: 'Д пней, см',
                        ),
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          labelText: 'Тип вырубки',
                          value: _selectedCuttingType,
                          items: _cuttingTypeOptions,
                          onChanged: (value) {
                            setState(() => _selectedCuttingType = value);
                          },
                        ),
                      ],
                    ),
                  ),
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
      decoration: _inputDecoration(labelText: labelText),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
      validator: (selectedValue) {
        if (selectedValue == null || selectedValue.isEmpty) {
          return 'Выберите значение';
        }

        return null;
      },
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
      decoration: _inputDecoration(labelText: labelText),
      validator: (value) =>
          _validatePositiveNumber(value, allowDecimal: allowDecimal),
    );
  }

  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  String? _validatePositiveNumber(String? value, {required bool allowDecimal}) {
    if (value == null || value.trim().isEmpty) {
      return 'Заполните поле';
    }

    final normalized = value.replaceAll(',', '.').trim();
    final parsedValue = allowDecimal
        ? double.tryParse(normalized)
        : int.tryParse(normalized);

    if (parsedValue == null) {
      return 'Введите корректное число';
    }

    if (parsedValue <= 0) {
      return 'Значение должно быть больше 0';
    }

    return null;
  }

  void _onSavePressed() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    context.read<PermanentPpBloc>().add(const PermanentPpEvent.sentInfo());
  }
}

final class _MainInfoSummary extends StatelessWidget {
  const _MainInfoSummary();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainInfoBloc, MainInfoState>(
      buildWhen: (previous, current) => previous.data != current.data,
      builder: (context, state) {
        final data = state.data;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SummaryItem(
                    label: 'Участковое лесничество',
                    value: _emptyDash(data.subForestry),
                  ),
                  const SizedBox(width: 12),
                  _SummaryItem(
                    label: 'Квартал',
                    value: data.quarter.toString(),
                  ),
                  const SizedBox(width: 12),
                  _SummaryItem(
                    label: 'Выдел',
                    value: data.allotment.toString(),
                  ),
                  const SizedBox(width: 12),
                  _SummaryItem(
                    label: 'Номер пробной площади',
                    value: data.samplePlotNumber.toString(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _emptyDash(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return '—';
    }

    return text;
  }
}

final class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 280),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
